#!/bin/bash

error=0
if [ $# -ge 1 ] && [[ $1 != "" ]]; then
	to=$1
else
	to="300.0"
fi

if [ $# -ge 2 ] && [[ $2 != "" ]]; then
        extrstart=$2
	extrlen=$3
	specsize=1
	if [ $# -eq 2 ] || [[ $3 == "" ]]; then
		error=1
	fi
else
	extrstart=0
	extrlen=0
	specsize=0
fi

if [ $# -lt 4 ]; then
	meanCols="if (ncol(input) >= 3) c(1, seq(3, ncol(input), 2)) else c(1)"
	sumCols="if (ncol(input) >= 2) c(1, seq(2, ncol(input), 2)) else c(1)"
	maxCols="c(1)"
	minCols="c(1)"
else
	if [ $# -gt 7 ]; then
		error=1
	else
		if [[ $4 == "" ]]; then
			meanCols="c(1)"
		else
			meanCols="c(1,$4)"
		fi
		if [[ $5 == "" ]]; then
			sumCols="c(1)"
		else
			sumCols="c(1,$5)"
		fi
		if [[ $6 == "" ]]; then
			maxCols="c(1)"
		else
			maxCols="c(1,$6)"
		fi
		if [[ $7 == "" ]]; then
			minCols="c(1)"
		else
			minCols="c(1,$7)"
		fi
	fi
fi

if [ $error -eq 1 ]; then
	echo "The aggregation script expects the following parameters:" >&2
	echo " \$1:      (optional) Timeout" >&2
	echo " \$2, \$3:  (optional) Start position and length of instance size information in the instance filenames (index origin 0)," >&2
	echo "                     or 0 0 for auto-detection. Default is auto-detection." >&2
	echo " \$4 - \$7: (optional) Comma-separated lists of columns to compute means, maxima, minima and sums of, respectively." >&2
	echo "                     Default:" >&2
	echo "                     Means of odd and sums of even columns (interpreted as times and timeouts, respectively)." >&2
	echo "In the input, column 1 is interpreted as instance size and used as the aggregation column." >&2
	exit 1
fi

aggregate="
	library(doBy);

	input <- read.table('stdin', header=FALSE, as.is=TRUE)

	# extract odd and even columns
	meanCols <- unique($meanCols)
	sumCols <- unique($sumCols)
	maxCols <- unique($maxCols)
	minCols <- unique($minCols)

	# make a copy of the table for each aggregation function,
	# where all columns not relevant to this function are 0
	emptytab <- input
	emptytab[, ] <- 0
	meanInput <- emptytab
	maxInput <- emptytab
	minInput <- emptytab
	sumInput <- emptytab
	meanInput[, meanCols] <- input[, meanCols]
	sumInput[, sumCols] <- input[, sumCols]
	maxInput[, maxCols] <- input[, maxCols]
	minInput[, minCols] <- input[, minCols]

	inputcomp <- input[,-1]
	if ( !all( (meanInput[,-1] + sumInput[,-1] + maxInput[,-1] + minInput[,-1]) == inputcomp) ){
		print(\"Error: There must be exactly one aggregation method specified for each column\");
		print(\"Mean columns:\")
		meanCols
                print(\"Sum columns:\")
                sumCols
                print(\"Min columns:\")
                minCols
                print(\"Max columns:\")
                maxCols
		return(1)
	}

	# compute the aggregation functions
	output <- emptytab
	meanResult <- summaryBy(.~V1, data=meanInput, FUN=mean)
	sumResult <- summaryBy(.~V1, data=sumInput, FUN=sum)
	maxResult <- summaryBy(.~V1, data=maxInput, FUN=max)
	minResult <- summaryBy(.~V1, data=minInput, FUN=min)

	# assemble the final result
	output <- meanResult
	output[,-1] <- output[,-1] + maxResult[,-1] + minResult[,-1] + sumResult[,-1]

	# compute for each column if it is an integer column
	outCols <- seq(1, ncol(output))
	isIntCol <- sapply(outCols,	function(x){
									return
									if (x == 1)
										FALSE
									else
										(all(round(output[, x], 0) == output[, x]))
								} )
	isNonIntCol <- sapply(outCols,	function(x){
										return
										if (x == 1)
											FALSE
										else
											(!all(round(output[, x], 0) == output[, x]))
									} )
	
	# rounding and output formatting
	outputformatted <- output

	if (!all(isNonIntCol)){
		intCols <- outCols[isIntCol[outCols]]
		outputformatted[, intCols] <- format(output[, intCols], nsmall=0)
	}
	if (!all(isIntCol)){
		nonIntCols <- outCols[isNonIntCol[outCols]]
		outputformatted[, nonIntCols] <- format(round(output[, nonIntCols], 2), nsmall=2)
	}

	# output
	write.table(outputformatted, , , FALSE, , , , , FALSE, FALSE)
	"

# add a trailing # in order to eliminate the last line if incomplete
data=$(mktemp)
cat > $data
echo "#" >> $data
while read line
do
	read -a array <<< "$line"
	if [[ $line != \#* ]]; then
		fn=${array[0]}

		# extract size
		if [[ $specsize -eq 0 ]]; then
			start=$(echo $fn | egrep "[0-9]*" -bo | head -n 1 | cut -f1 -d':')
			len=$(echo $fn | egrep "[0-9]*" -bo | head -n 1 | cut -f2 -d':')
			len=${#len}
			if [[ $extrstart -eq 0 ]] && [[ $extrlen -eq 0 ]]; then
				extrstart=$start
				extrlen=$len
			else
				if [[ $# -le 2 ]]; then
					if [[ $start -ne $extrstart ]]; then
						echo "Could not extract instance size due to inconsistent naming; please specify start and length of size within the filename manually"
						exit 1
					fi
					extrlen=$len
				fi
			fi
		fi

		if [ $extrlen -ge 1 ]; then
			array[0]="${fn:$extrstart:$extrlen}"
		else
			array[0]="${array[0]}"
		fi
	        line=$(echo ${array[@]} | grep -v "#")
		file=$(echo "$file\n$line")
	fi
done < $data

# check results
failedinstances=$(echo -e "$file" | grep "FAIL" | wc -l)
failedconfigurations=$(echo -e "$file" | grep -o "FAIL" | wc -l)
file=$(echo -e "$file" | grep -v "FAIL")
unknowninstances=$(echo -e "$file" | grep "???" | wc -l)
unknownvalues=$(echo -e "$file" | grep -o "???" | wc -l)

inputlines=$(echo -ne "$file" | wc -l)

# keep comments
cat $data | grep "#"

# actual aggregation
if [[ $inputlines -gt 0 ]]; then
	rerrfile=$(mktemp)
	echo -e "$file" | sed "s/---/$to/g;s/===/$to/g" | sed 's/???/0/g' | Rscript <(echo "$aggregate") 2>$rerrfile
	if [[ $? -ne 0 ]]; then
		echo "Aggregation failed, R yielded the following error:" >&2
		cat $rerrfile
		ret=1
	fi
        rm $data
        rm $rerrfile
fi

if [ $unknowninstances -gt 0 ]; then
       	echo -e "# Warning: $unknownvalues measured values in $unknowninstances instances are unknown, they were treated as 0 for aggregation." 2>&1
fi
if [ $failedinstances -gt 0 ]; then
        echo -e "# Warning: $failedconfigurations configurations in $failedinstances instances failed, table contains only the results of the successful instances!." 2>&1
fi
if [[ $inputlines -eq 0 ]]; then
        echo -e "# Warning: There were no results of successful instances, therefore the aggregation output is empty"
fi
exit $ret
