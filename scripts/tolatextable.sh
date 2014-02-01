# $1: LaTeX package to use for generating headers (currently supported: default, booktabs)
#     If $1 is missing, then only the body of the table is generated
if [[ $# -ge 1 ]]; then
	if [[ $1 == "default" ]]; then
		toprule="hline"
		midrule="hline"
		bottomrule="hline"
	elif [[ $1 == "booktabs" ]]; then
		toprule="toprule"
		midrule="midrule"
		bottomrule="bottomrule"
	else
		echo "LaTeX table package \"$1\" unknown, currently supported: default, booktabs"
		exit 1
	fi
fi

first=1
while read line
do
	read -a array <<< "$line"

	# compute the the max size of every timeout column
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
		if [[ $first == 0 ]]; then
			file="$file\n"
		fi
		first=0
		file="$file$line"
	fi
done

if [[ $# -ge 1 ]]; then
	# generate header
	echo -e "\\\\begin{table}[t]"
	echo -e "\t\\\\scriptsize"
	echo -e "\t\\\\centering"
        echo -e "\t%\\\\rowcolors{2}{white}{gray!25}"
	for (( c=1; c <= $cols / 2 - 1; c++ ))
	do
		coldef="${coldef}r"
		colsep="$colsep & col$c"
	done
	echo -e "\t\\\\begin{tabular}[t]{r|$coldef}"
	echo -e "\t\t\\\\$toprule"
	echo -e "\t\tinstance$colsep \\\\\\\\"
	echo -e "\t\t\\\\$midrule"
fi

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
	if [[ $# -ge 1 ]]; then
		echo -e "\t\t$out"
	else
		echo -e "$out"
	fi
done

if [[ $# -ge 1 ]]; then
	echo -e "\t\t\\\\$bottomrule"
	echo -e "\t\\\\end{tabular}"
	echo -e "\t\\\\caption{Benchmark Results}"
	echo -e "\t\\\\label{tab:benchmark}"
	echo -e "\\\\end{table}"
fi
