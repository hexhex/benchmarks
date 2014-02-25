#! /bin/bash

for (( i=1; i<=$#; i++ ))
do
	bmname=${!i}
	current=$PWD/$bmname/$bmname.dat
	reference=$PWD/$bmname/$bmname.ref

	if [ ! -e $current ] || [ ! -e $reference ]; then
		echo "Benchmark results of $bmname not found: results expected at $current and reference output at $reference"
		err="$err 0 $current"
	else
	        echo "Checking benchmark $bmname" >&2

	        if [ -e $PWD/$bmname/compare.sh ]; then
        	        echo "Using customized comparison script $PWD/$bmname/compare.sh"
			$PWD/$bmname/compare.sh $current $reference
			compres=$?
	        else
			echo "Using default comparison method"

			fname=$(mktemp)
			rname=$(mktemp)
			cat $current | grep -v "#" > $fname
			cat $reference | grep -v "#" > $rname

        	        script=$(echo "
                	        res <- read.table('$fname', header=FALSE, as.is=TRUE)
                        	ref <- read.table('$rname', header=FALSE, as.is=TRUE)

				# a change is ok, if either the relative difference is less than 10% or the absolute difference is less than 5
				compresult = (res/ref < 1.1 & res/ref > 0.9) | (abs(res - ref) < 5)
	
				if ( all(compresult) ){
					print(\"ack\")
				}else{
					print(\"nak\")
				}
        	                ")

			ack=$(Rscript <(echo "$script") | grep "ack" | wc -l)
			compres=$?
			if [[ $compres -eq 0 ]] && [[ $ack -eq 0 ]]; then
				compres=2
			fi
		fi

		if [[ $compres -eq 0 ]]; then
                        echo "There were no significant changes in benchmark $bmname"
		elif [[ $compres -eq 1 ]] || [[ $compres -gt 2 ]]; then
			echo "There was a comparison error in benchmark $bmanme"
			err="$err 0 $current"
		elif [[ $compres -eq 2 ]]; then
			echo "There were significant changes in benchmark $bmname"
			echo "Current results:"
			cat $current
			echo "Reference results:"
			cat $reference
			chbm="$chbm 0 $bmname"
		fi

                rm $fname
                rm $rname
	fi
done

if [[ $chbm != "" ]] || [[ $err != "" ]]; then
	if [[ $mail != "" ]]; then
		sendnotification.sh "Automatic Check" "$mail" 0 Significant_Changes $chbm 0 Failed_Comparisons $err
	fi
	exit 1
else
	exit 0
fi
