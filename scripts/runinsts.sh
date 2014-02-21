# $1: condor or sequential
# $1: instance loop condition
# $2: single benchmark command
# $3: working directory
# $4: timeout
# $5: requirements file
# $6: custom aggregation script

if [ $# -gt 6 ] || [ $# -eq 1 ] && [[ $1 == "?" ]]; then
	echo "This script needs 0 to 5 parameters:" 1>&2
	echo " \$1: (optional) Instance loop condition (default: *.hex)" 1>&2
        echo " \$2: (optional) Single benchmark command (default: ./run.sh)" 1>&2
        echo " \$3: (optional) Working directory (default: PWD)" 1>&2
	echo " \$4: (optional) Timeout (default: 300)" 1>&2
        echo " \$5: (optional) requirements file" 1>&2
        echo " \$6: (optional) custom aggregation script (default: ./aggregateresults.sh)" 1>&2
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
if [ $# -ge 4 ]; then
        to=$4
else 
        to=300
fi
if [ $# -ge 6 ]; then
        aggscript=$6
else 
        aggscript=$helperscriptdir/aggregateresults.sh
fi

# check if there is a requirements file
# priorities: 1. command-line parameter, 2. directory of single benchmark script, 3. directory of this script
if [ $# -ge 5 ]; then
	reqfile=$5
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
	echo "   $cmd $PATH $LD_LIBRARY_PATH $instance $to" 1>&2
	if [ $sequential -eq 0 ]; then
		# prepare single jobs
		echo "
			Executable = $cmd
			Output = $instance.out
			Error = $instance.error
			Log = $instance.log
			$requirements
			Initialdir = $workingdir
			Notification = never
			getenv = true

			# queue
			Arguments = single $instance $to "$helperscriptdir"
			Queue 1
		     " > $instance.job
		dagman="${dagman}Job ${instance} ${instance}.job\n"
		alljobs="$alljobs ${instance}"
	else
		$workingdir/$cmd single $instance $to "$helperscriptdir" >$instance.out 2>$instance.error
		cat $instance.out
		cat $instance.error >&2
	fi
	resultfiles="$resultfiles $instance.out"
done
if [ $sequential -eq 0 ]; then
	# prepare a job for aggregation of the results
	echo -e "
			Executable = $aggscript
			Output = results_$loop.dat
			Error = results_$loop.err
			Log = results_$loop.log
			Input = $resultfiles
			$requirements
			Initialdir = $workingdir
			Notification = never
			getenv = true

			# queue
			Arguments = $to
			Queue 1
		"

	# acutally submit them
	echo -e "
			$dagman
			Job AggregationJob
			PARENT $alljobs CHILD AggregationJob
		" | condor_dagman 
else
	# aggregate results
	if [[ $resultfiles != "" ]]; then
		echo "Aggregating results in file results_$loop.dat" 1>&2
		rerrfile=$(mktemp)
		echo "" > results_$loop.dat
		cat $resultfiles | $aggscript >results_$loop.dat 2>results_$loop.err
		if [[ $? -ne 0 ]]; then
			echo "Aggregation failed" >> results_$loop.dat
			echo "Input to R:" >> results_$loop.dat
			echo $resultfiles >> results_$loop.dat
			echo "Error output from R:" >> results_$loop.dat
			echo results_$loop.err >> results_$loop.dat
		fi
		rm results_$loop.err
	else
		echo "" > "results_$loop.dat"
	fi
	echo "Benchmark finished" 1>&2
fi
