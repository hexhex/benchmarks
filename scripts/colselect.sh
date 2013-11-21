while read line
do
	line=$(echo $line | sed "s/\\\\//g")
	IFSB=$IFS
	IFS='&'
	cols=($line)
	IFS=$IFSB

	echo -n "${cols[0]}"
	
	for (( i = 1 ; i <= $# ; i=$i+1 ));
	do
	        echo -n "&${cols[${!i}]}"
	done
	echo "\\\\"
done
