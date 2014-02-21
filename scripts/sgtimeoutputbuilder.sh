# This script transforms the execution result of a single dlvhex command into a time string consisting of overall and separate grounding and solving time

if [ $# != 4 ]; then
	echo "This script expects 4 parameters"
	echo " $1: return value of command"
	echo " $2: timefile"
	echo " $3: stdout of command"
	echo " $4: stderr of command"
	echo ""
	echo " Return value:"
	echo "	0 if output for successful instance was generated"
	echo "	1 if output builder itself failed"
	echo "	2 if detailed instance failure should be reported to stderr"
	exit 1
fi

ret=$1
timefile=$2
stdout=$3
sterr=$4
if [[ $ret == 124 ]]; then
	echo -ne "--- 1 --- 1 --- 1"
	exit 0
elif [[ $ret != 0 ]]; then
	echo -ne "FAIL x x x"
	exit 2
else
	# get overall time
	time=$(cat $timefile)

	# check if there is a grounding and solving time (should be the case for successful instances)
	groundertime=$(cat $sterr | grep -a "HEX grounder time:")
	solvertime=$(cat $sterr | grep -a "HEX solver time:")
	haveGroundertime=$(echo -ne $groundertime | wc -l)
	haveSolvertime=$(echo -ne $solvertime | wc -l)
	if [[ $haveGroundertime -eq 0 ]] || [[ $haveSolvertime -eq 0 ]]; then
		echo "Instance did not provide grounder and solver time" >&2
		groundertime="???"
		solvertime="???"
	else
		# extract grounding and solving time
		groundertime=$(echo $groundertime | tail -n 1 | grep -P -o '[0-9]+\.[0-9]+s' | sed "s/s//")
		solvertime=$(echo $solvertime | tail -n 1 | grep -P -o '[0-9]+\.[0-9]+s' | sed "s/s//")

		# round to two digits
		groundertime=$(echo "scale=2; $groundertime/1" | bc)
		solvertime=$(echo "scale=2; $solvertime/1" | bc)
	fi

	echo -ne "$time 0 $grundertime 0 $solvertime 0"
	exit 0
fi
exit 1
