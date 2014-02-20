# $1: instance loop condition
# $2: single benchmark command
# $3: working directory
# $4: timeout
# $5: requirements file

if [ $# -gt 5 ] || [ $# -eq 1 ] && [[ $1 == "?" ]]; then
	echo "This script needs 0 to 5 parameters:" 1>&2
	echo " \$1: instance loop condition (default: *.hex)" 1>&2
        echo " \$2: single benchmark command (default: ./benchmark_single.sh)" 1>&2
        echo " \$3: working directory (default: PWD)" 1>&2
	echo " \$4: timeout (default: 300)" 1>&2
        echo " \$5: (optional) requirements file (use NOCONDOR to run the instances in sequence)" 1>&2
	echo "" 1>&2
	echo "The script will pass 4 parameters to the single benchmark command:" 1>&2
	echo " \$1: PATH variable" 1>&2
	echo " \$2: LD_LIBRARY_PATH variable" 1>&2
	echo " \$3: instance name" 1>&2
	echo " \$4: timeout" 1>&2
	exit 1
fi

# default parameters
if [ $# -ge 1 ]; then
        loop=$1
else
        loop="*.hex"
fi

if [ $# -ge 2 ]; then
        cmd=$2
else
        cmd="./benchmark_single.sh"
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

# check if there is a requirements file
# priorities: 1. command-line parameter, 2. directory of single benchmark script, 3. directory of this script
condor=1
if [ $# -ge 5 ] && [[ $5 == "NOCONDOR" ]]; then
	condor=0
elif [ $# -ge 5 ]; then
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
if [ $condor -eq 1 ]; then  
	echo "Requirements:      $reqfile" 1>&2
	cat $reqfile | sed 's/^/                   /' 1>&2
else
	echo "Sequential mode" 1>&2
fi

# schedule all instances
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
			Arguments = "$PATH" "$LD_LIBRARY_PATH" $instance $to
			Queue 1
		     " | condor_submit
	else
		$cmd $PATH $LD_LIBRARY_PATH $instance $to
	fi
	echo "" 1>&2
done

