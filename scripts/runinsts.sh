# $1: condor or sequential
# $1: instance loop condition
# $2: single benchmark command
# $3: working directory
# $4: timeout
# $5: custom aggregation script
# $6: Name of the benchmark
# $7: requirements file

if [ $# -gt 6 ] || [ $# -eq 1 ] && [[ $1 == "?" ]]; then
	echo "This script needs 0 to 5 parameters:" 1>&2
	echo " \$1: (optional) Instance loop condition (default: *.hex)" 1>&2
        echo " \$2: (optional) Single benchmark command (default: ./run.sh)" 1>&2
        echo " \$3: (optional) Working directory (default: PWD)" 1>&2
	echo " \$4: (optional) Timeout (default: 300)" 1>&2
        echo " \$5: (optional) custom aggregation script (default: ./aggregateresults.sh)" 1>&2
	echo " \$6: (optional) Name of the benchmark (default: name of the working directory)" 1>&2
        echo " \$7: (optional) requirements file" 1>&2
	echo "" 1>&2
	echo "The script will pass 4 parameters to the single benchmark command:" 1>&2
	echo " \$1: PATH variable" 1>&2
	echo " \$2: LD_LIBRARY_PATH variable" 1>&2
	echo " \$3: Instance name" 1>&2
	echo " \$4: Timeout" 1>&2
	echo " \$5: Directory which contains the benchmark helper scripts (directory of this script)" 1>&2
	echo "" 1>&2
	echo "Template for a run.sh script:" 1>&2
	echo "      ./runconfigs.sh \"dlvhex2 INST\"" "--solver=genuinegc;--solver=genuineii\" $3 $4" 1>&2
	echo "" 1>&2
	echo "Template for a req file:" 1>&2
	echo "      Universe = vanilla" 1>&2
	echo "      Requirements = machine == \"lion.kr.tuwien.ac.at\"" 1>&2
	echo "      request_memory = 8192" 1>&2
	echo "" 1>&2
	echo "The script will execute all instances and aggregate their results" 1>&2
	echo "in a table called \"results_$1.dat\"" 1>&2
	exit 1
fi

helperscriptdir="$(dirname $0)"

# default parameters
if [ $# -ge 1 ]; then
        loop=$1
else
        loop="*.hex"
fi
if [ $# -ge 2 ]; then
        cmd=$2
else
        cmd="./run.sh"
fi
if [ $# -ge 3 ]; then
        workingdir=$3
else
        workingdir=$PWD
fi
workingdir=$(cd $workingdir; pwd)
if [ $# -ge 4 ]; then
        to=$4
else 
        to=300
fi
if [ $# -ge 5 ]; then
        aggscript=$5
else 
        aggscript=$helperscriptdir/aggregateresults.sh
fi
if [ $# -ge 6 ]; then
	benchmarkname=$6
else
	benchmarkname=$(cd $workingdir; pwd)
	benchmarkname=$(basename $benchmarkname)
fi

# Make sure that the output directory exists
outputdir="$workingdir/$benchmarkname.output"
if [ -e "$outputdir" ]; then
	echo "Output directory already exists, type \"del\" to confirm overwriting"
	read inp
	if [[ $inp != "del" ]]; then
		echo "Will NOT overwrite the existing directory. Aborting benchmark execution!"
		exit 1
	fi
	rm -r $outputdir
fi
mkdir -p $outputdir
outputdir=$(cd $outputdir; pwd)

# check if there is a requirements file
# priorities: 1. command-line parameter, 2. directory of single benchmark script, 3. directory of this script
if [ $# -ge 6 ]; then
	reqfile=$6
	requirements=$(cat $reqfile 2> /dev/null)
	if [ $? -ne 0 ]; then
		echo "Error: Requirements file $reqfile invalid" 1>&2
		exit 1
	fi
else
	reqfile=$(dirname $cmd)/req
	requirements=$(cat $reqfile 2> /dev/null)
	if [ $? -ne 0 ]; then
		reqfile=$(dirname $0)/req
		requirements=$(cat $reqfile 2> /dev/null)
		if [ $? -ne 0 ]; then
			echo "Requirements file not found" 1>&2
			exit 1
		fi
	fi
fi

# print summary
echo "=== Running benchmark \"$benchmarkname\"" 1>&2
echo "" 1>&2
echo "Loop:              $loop" 1>&2
echo "Command:           $cmd" 1>&2
echo "Working directory: $workingdir" 1>&2
echo "Timeout:           $to" 1>&2

# check if we use condor
req=$(cat $reqfile | sed '/^$/d')
if [[ $req != "sequential" ]]; then  
	echo "Requirements:      $reqfile" 1>&2
	cat $reqfile | sed 's/^/                   /' 1>&2
	sequential=0
else
	echo "Sequential mode" 1>&2
	sequential=1
fi

# schedule all instances
cd $workingdir
for instance in $(eval "echo $loop")
do
	echo "Instance $instance:" 1>&2
	echo "   cd $workingdir" 1>&2
	echo "   $cmd single \"$instance\" \"$to\" \"$helperscriptdir\"" 1>&2
	mkdir -p $outputdir/$instance
	if [ $sequential -eq 0 ]; then
		# prepare single jobs
		echo "
			Executable = $cmd
			Output = $outputdir/$instance.out
			Error = $outputdir/$instance.error
			Log = $outputdir/$instance.log
			$requirements
			Initialdir = $workingdir
			Notification = never
			getenv = true

			# queue
			Arguments = single $instance $to $helperscriptdir
			Queue 1
		     " > $outputdir/$instance.job
		dagman="${dagman}Job InstJob${instance} $outputdir/${instance}.job\n"
		instjobs="$instjobs InstJob${instance}"
	else
		$workingdir/$cmd single "$instance" "$to" "$helperscriptdir" >$outputdir/$instance.out 2>$outputdir/$instance.error
		cat $outputdir/$instance.out
		cat $outputdir/$instance.error >&2
	fi
	resultfiles="$resultfiles $outputdir/$instance.out"
done
if [ $sequential -eq 0 ]; then
        echo -e "
                        Executable = $(which cat)
                        Output = $outputdir/allout.dat
                        Error = $outputdir/allout.err
                        Log = $outputdir/allout.log
                        $requirements
                        Initialdir = $outputdir
                        Notification = never
                        getenv = true

                        # queue
                        Arguments = $resultfiles 
                        Queue 1
                " > $outputdir/allout.job

	# prepare a job for aggregation of the results
	echo -e "
			Executable = $aggscript
			Output = $outputdir/$benchmarkname.dat
			Error = $outputdir/$benchmarkname.err
			Log = $outputdir/$benchmarkname.log
			Input = $outputdir/allout.dat
			$requirements
			Initialdir = $workingdir
			Notification = never
			getenv = true

			# queue
			Arguments = $to
			Queue 1
		" > $outputdir/agg.job

	# acutally submit them
	echo -e "
			$dagman
			Job AlloutJob $outputdir/allout.job
			Job AggJob $outputdir/agg.job
			PARENT $instjobs CHILD AlloutJob
			PARENT AlloutJob CHILD AggJob
		" > "$outputdir/$benchmarkname.dag"
		condor_submit_dag $outputdir/$benchmarkname.dag
	if [ $? -ne 0 ]; then
		echo "Error while scheduling benchmark \"$benchmarkname\" for execution" >&2
		exit 1
	fi

        echo "Benchmark \"$benchmarkname\" scheduled for execution" 1>&2
else
	# aggregate results
	if [[ $resultfiles != "" ]]; then
		echo "Aggregating results in file $outputdir/$benchmarkname.dat" 1>&2
		rerrfile=$(mktemp)
		echo "" > $outputdir/$benchmarkname.dat
		cat $resultfiles | $aggscript >$outputdir/$benchmarkname.dat 2>$outputdir/$benchmarkname.err
		if [[ $? -ne 0 ]]; then
			echo "Aggregation failed" >> $outputdir/$benchmarkname.dat
			echo "Input to R:" >> $outputdir/$benchmarkname.dat
			echo $resultfiles >> $outputdir/$benchmarkname.dat
			echo "Error output from R:" >> $outputdir/$benchmarkname.dat
			echo $outputdir/$benchmarkname.err >> $outputdir/$benchmarkname.dat
		fi
		rm $rerrfile
	else
		echo "" > "$outputdir/$benchmarkname.dat"
	fi
	echo "Benchmark \"$benchmarkname\" finished" 1>&2
fi
