#!/bin/bash

# The parameters specify the columns to select (index-origin 1)
while read line
do
	cols=($line)

	# instance size and number of instances
	echo -n "${cols[0]} ${cols[1]}"
	
	for (( i = 1 ; i <= $# ; i=$i+1 ));
	do
		timeindex=$((2+(${!i}-1)*2))
		toindex=$(($timeindex+1))
	        echo -n " ${cols[$timeindex]} ${cols[$toindex]}"
	done
	echo ""
done
