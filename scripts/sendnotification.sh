#!/bin/bash

# Sends an e-mail notification about a finished benchmark
# $1: Name of the benchmark
# $2: Receiver e-mail address
# All further pairs of parameters $i/$i+1 append content to the e-mail, where an odd $i is interpreted as boolean if $i+1 should be interpreted as file (1) or as string (0)
benchmarkname=$1
receiver=$2

if [[ $# -lt 2 ]]; then
	echo "Sends an e-mail notification about a finished benchmark" >&2
	echo "This script expects the following parameters:" >&2
	echo "  \$1: Name of the benchmark" >&2
        echo "  \$2: Receiver e-mail addres" >&2
        echo "All further pairs of parameters \$i/\$i+1 append content to the e-mail," 2>&1
	echo "where an odd \$i is interpreted as boolean if \$i+1 should be interpreted" 2>&1
	echo "as file (1) or as string (0)" 2>&1
	exit 1
fi

text="Benchmark \"$benchmarkname\" has finished on $(date)!"
for ((i=3; i<=$#; i++))
do
	if [[ $i%2 -eq 0 ]]; then
		if [[ $fromfile -eq 1 ]]; then
			echo "Reading file ${!i}"
			file=$(cat ${!i})
			text="$text\n\n$file"
		else
			text="$text\n\n${!i}"
		fi
	else
		fromfile=${!i}
	fi
done
echo "Sending the following message to $receiver:"
echo -e "$text"
echo -e "$text" | mail -s "dlvhex benchmark $benchmarkname finished" $receiver
