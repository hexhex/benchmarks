#!/bin/bash

# This script transforms the execution result of a single command into a time string

if [ $# != 4 ]; then
	echo "This script expects 4 parameters"
	echo " \$1: return value of command"
	echo " \$2: timefile"
	echo " \$3: stdout of command"
	echo " \$4: stderr of command"
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
	echo -ne "--- 1 $(cat $stdoutfile | wc -l)"
	exit 0
elif [[ $ret != 0 ]]; then
        # check if it is a memout
        if [ $(cat $stderrfile | grep "std::bad_alloc" | wc -l) -gt 0 ]; then
                echo -ne "=== 1 $(cat $stdoutfile | wc -l)"
                exit 0
        else
                echo -ne "FAIL x y"
                exit 2
        fi
else
	time=$(cat $timefile)
	echo -ne "$time 0 $(cat $stdoutfile | wc -l)"
	exit 0
fi
exit 1
