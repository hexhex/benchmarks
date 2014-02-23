#!/bin/bash

# The parameters specify the columns to select (index-origin 0)
while read line
do
	if [[ $line == \#* ]]; then
		if [[ $line == \#*Configuration:* ]]; then
	                conf=$(echo $line | cut -d':' -f2)
        	        origIFS=$IFS
                	IFS=';' read -a confs <<< "$conf"
			echo -n "# Configuration:"
			for (( i=1; i <=$#; i++ ))
			do
				if [[ $i -gt 1 ]]; then
					echo -n ";"
				fi
				index=${!i}
				let index=$index-1
				echo -n "${confs[$index]}"
			done
			IFS=$origIFS
			echo ""
		else
			echo $line
		fi
	else
		cols=($line)

		for (( i = 1 ; i <= $# ; i++ ));
		do
			index=${!i}
			let index=$index-1
			if [[ $i -gt 1 ]]; then
				echo -n " "
			fi
	        	echo -n "${cols[$index]}"
		done
		echo ""
	fi
done
