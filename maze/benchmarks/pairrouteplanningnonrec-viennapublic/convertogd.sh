while read line
do
	c=$(echo $line | sed 's/;/,/g')
	echo "$2($c)."
done < $1
