first=1
while read line
do
	read -a array <<< "$line"

	# the the max size of every timeout column
	cols=$(echo $line | wc -w)
	for (( c=2; c <= $cols; c=c+2 ))
	do
		len=$(echo $line | cut -d' ' -f$c | wc -c)
		if [[ ${max[$c]} -lt $len ]]; then
			max[$c]=$len
		fi
	done

	if [[ $line != \#* ]]; then
		fn=${array[0]}
		line=$(echo ${array[@]} | grep -v "#")
		if [[ $first == 0 ]]; then
			file="$file\n"
		fi
		first=0
		file="$file$line"
	fi
done

echo -e "$file" | while read -r line
do
	out=$(echo -e "$line" | sed "s/ *\([^ ]*\) *\([^ ]*\) */\1 (\2) \& /g" | sed 's/& $/\\\\\\\\/')

	# for all timeout columns
	for (( c=2; c <= $cols; c=c+2 ))
	do
		t=$(($c / 2))
		len=$(echo $line | cut -d' ' -f$c | wc -c)

		# add ${max[$c]} - $len copies of "~~"
		nr=$((${max[$c]} - $len))
		for (( i=0; i < nr; ++i ))
		do
			out=$(echo $out | sed "s/(/~~(/$t")
		done
	done
	echo -e "$out"

done
