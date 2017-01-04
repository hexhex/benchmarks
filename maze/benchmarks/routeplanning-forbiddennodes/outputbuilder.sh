#!/bin/bash

# This script transforms the execution result of a single command into a time string

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
stdoutfile=$3
stderrfile=$4
if [[ $ret == 124 ]] || [[ $ret == 137 ]]; then
	echo -ne "--- 1 --- --- ??? ??? ??? ???"
	exit 0
elif [[ $ret != 0 ]]; then
	if [ $(cat $stderrfile | grep "std::bad_alloc" | wc -l) -gt 0 ]; then
		echo -ne "=== 1 === === ??? ??? ??? ???" 
		exit 0
	else
		echo -ne "FAIL x y x a b c d"
		exit 2
	fi
else
	# extract timeing information
	time=$(cat $timefile)
	groundertime=$(cat $stderrfile | grep -a "HEX grounder time:")
	solvertime=$(cat $stderrfile | grep -a "HEX solver time:")
	haveGroundertime=$(echo $groundertime | wc -l)
	haveSolvertime=$(echo $solvertime | wc -l)

	if [[ $haveGroundertime -eq 0 ]] || [[ $haveSolvertime -eq 0 ]]; then
		echo "Instance did not provide grounder and solver time" >&2
		groundertime="???"
		solvertime="???"
	else
		# extract grounding and solving time
		groundertime=$(echo "$groundertime" | tail -n 1 | grep -P -o '[0-9]+\.[0-9]+s' | sed "s/s//")
		solvertime=$(echo "$solvertime" | tail -n 1 | grep -P -o '[0-9]+\.[0-9]+s' | sed "s/s//")

		# round to two digits
		groundertime=$(echo "scale=2; $groundertime/1" | bc | sed 's/^\./0\./')
		solvertime=$(echo "scale=2; $solvertime/1" | bc | sed 's/^\./0\./')
	fi

	# benchmark-specific information
	pathexists=$(cat $stdoutfile | wc -l)
	pathlen=$(cat $stdoutfile | sed 's/{//' | sed 's/}//' | sed 's/),/),\n/g' | grep "^orderedpath(" | cut -d"," -f 4 | sed 's/^/.+/' | bc | tail -1)
	pathlen=$(echo -e "$pathlen\n.+0" | bc | tail -1)
	changes=$(cat $stdoutfile | sed 's/{//' | sed 's/}//' | sed 's/),/),\n/g' | grep "^path(" | grep "change" | wc -l)
	restaurant=$(cat $stdoutfile | sed 's/{//' | sed 's/}//' | sed 's/),/),\n/g' | grep "^needRestaurant" | wc -l)
	echo -ne "$time 0 $groundertime $solvertime $pathexists $pathlen $changes $restaurant"
	exit 0
fi
exit 1
