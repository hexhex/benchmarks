# $1: condor or sequential
# $1: instance loop condition
# $2: single benchmark command
# $3: working directory
# $4: timeout
# $5: requirements file

if [ $# -gt 5 ] || [ $# -eq 1 ] && [[ $1 == "?" ]]; then
	echo "This script needs 0 to 5 parameters:" 1>&2
	echo " \$1: Condor or sequential execution: 0 for sequential, !=0 for condor (default: 0)" 1>&2
	echo " \$2: Instance loop condition (default: *.hex)" 1>&2
        echo " \$3: Single benchmark command (default: ./run.sh)" 1>&2
        echo " \$4: Working directory (default: PWD)" 1>&2
	echo " \$5: Timeout (default: 300)" 1>&2
        echo " \$6: (optional) requirements file" 1>&2
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
	exit 1
fi

# check if we use condor
if [ $# -ge 1 ] && [[ $1 != 0 ]]; then
	condor=1
else
	condor=0
fi

# default parameters
if [ $# -ge 2 ]; then
        loop=$2
else
        loop="*.hex"
fi

if [ $# -ge 3 ]; then
        cmd=$3
else
        cmd="./run.sh"
fi

if [ $# -ge 4 ]; then
        workingdir=$4
else
        workingdir=$PWD
fi

if [ $# -ge 5 ]; then
        to=$5
else 
        to=300
fi

# check if there is a requirements file
# priorities: 1. command-line parameter, 2. directory of single benchmark script, 3. directory of this script
if [ $condor -eq 1 ]; then
	if [ $# -ge 6 ]; then
		reqfile=$6
		requirements=$(cat $reqfile 2> /dev/null)
		if [ $? -ne 0 ]; then
			echo "Error: Condor requirements file $reqfile invalid" 1>&2
			exit 1
		fi
	else
		reqfile=$(dirname $cmd)/req
		requirements=$(cat $reqfile 2> /dev/null)
		if [ $? -ne 0 ]; then
			reqfile=$(dirname $0)/req
			requirements=$(cat $reqfile 2> /dev/null)
			if [ $? -ne 0 ]; then
				echo "Condor requirements file not found" 1>&2
				exit 1
			fi
		fi
	fi
fi

# print summary
echo "Loop:              $loop" 1>&2
echo "Command:           $cmd" 1>&2
echo "Working directory: $workingdir" 1>&2
echo "Timeout:           $to" 1>&2
if [ $condor -eq 1 ]; then  
	echo "Requirements:      $reqfile" 1>&2
	cat $reqfile | sed 's/^/                   /' 1>&2
else
	echo "Sequential mode" 1>&2
fi

# schedule all instances
helperscriptdir="$(dirname $0)"
cd $workingdir
for instance in $(eval "echo $loop")
do
	echo "Instance $instance:" 1>&2
	echo "   cd $workingdir" 1>&2
	echo "   $cmd $PATH $LD_LIBRARY_PATH $instance $to" 1>&2
	if [ $condor -eq 1 ]; then
		echo "
			Executable = $cmd
			output = $instance.out
			error = $instance.error
			Log = $instance.log
			$requirements
			Initialdir = $workingdir
			notification = never

			# queue
			Arguments = "$PATH" "$LD_LIBRARY_PATH" $instance $to "$helperscriptdir"
			Queue 1
		     " | condor_submit
	else
		$workingdir/$cmd "$PATH" "$LD_LIBRARY_PATH" $instance $to "$helperscriptdir"
	fi
done

