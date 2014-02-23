#!/bin/bash

# merged benchmark tables line-wise
if [[ $# == 0 ]]
then
	exit 0
fi

cmd="paste -d ' '"
for (( i=1; i<=$#; i++ ))
do
	if [[ $i -ge 2 ]]; then
		cmd="$cmd <(cat ${!i} | sed 's/\# *Benchmark\:.*//' | sed 's/\# *Configuration\: */;/' | sed 's/^ *//g' | sed 's/ \+/ /g')"
	else
                cmd="$cmd <(cat ${!i} | sed 's/^ *//g' | sed 's/ \+/ /g')"
	fi
done
eval $cmd | sed '/\# *Configuration\:/s/ \;/\;/g'
