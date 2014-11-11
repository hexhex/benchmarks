#!/bin/bash

# Interpret parameters
if [[ $# -ge 1 ]]; then
	if [[ $1 == "none" ]] || [[ $1 == "" ]]; then
		createheader=0
        elif [[ $1 == "standard" ]]; then
		createheader=1
                toprule="hline"
                midrule="hline"
                bottomrule="hline"
        elif [[ $1 == "booktabs" ]]; then
		createheader=1
                toprule="toprule"
                midrule="midrule"
                bottomrule="bottomrule"
        else
		error=1
        fi
fi
if [[ $# -ge 2 ]] && [[ $2 != "" ]]; then
	userpattern=1
fi
if [[ $# -ge 3 ]]; then
	if [[ $3 == "subst" ]]; then
		patternconvenience=1
	else
		error=1
	fi
fi

if [[ $error -eq 1 ]]; then
	echo "This script transforms tables in text format, as produced by the dlvhex benchmark scripts, into LaTeX tables." >&2
	echo "Parameters:" >&2
	echo " \$1: (optional) LaTeX package to use for creating table header" >&2
	echo "                 Valid values: none, standard, booktabs" >&2
	echo "                 Default value: none (produces only table body)" >&2
	echo " \$2: (optional) Pattern how to format each line (without final \\\\)" >&2
	echo "                 The string may consists of constant parts and expressions of form" >&2
	echo "                   \${val[i]} to refer to the value of the i-th colum" >&2
	echo "                 or" >&2
	echo "                   \${fill[i]}" >&2
	echo "                 to refer to a sequence of double-tile (~~) required to align this column" >&2
	echo "                 Default value: \${val[0]} \${fill[1]}(${val[1]}) & \${val[2]} \${fill[3]}(\${val[3]}) & ..." >&2
	echo "                 (pairs of columns are put in the same LaTeX table with even columns being interpreted as times" >&2
	echo "                  and odd ones as timeouts which are put in parentheses)" >&2
	echo " \$3: (optional) subst" >&2
	echo "                 for a more convenient syntax for \$2: \${val[i]} and \${fill[i]} can be written as val[i] and fill[i], respectively" >&2
	exit 1
fi

# compute column lengths and default pattern
first=1
label="results"
while read line
do
	if [[ $line != \#* ]]; then
		val=($line)
		for ((c=0; c<${#val[@]}; c++))
		do
                        len=$(echo -ne ${val[$c]} | wc -c)
                        if [[ ${max[$c]} -lt $len ]]; then
                                max[$c]=$len
                        fi
		done
		if [[ $notfirst -gt 0 ]]; then
			file="$file\n$line"
		else
			notfirst=1
			file="$line"
		fi
	elif [[ $line == \#*Configuration:* ]]; then
		conf=$(echo $line | cut -d':' -f2)
        elif [[ $line == \#*Benchmark:* ]]; then
	        benchmarkname=$(echo $line | cut -d':' -f2)
		captionprefix="$benchmarkname "
		label="$benchmarkname-results"
	fi
done
for ((c=0; c<${#val[@]}; c++))
do
	# construct default pattern
        if [[ $userpattern -eq 0 ]] && [ $((c%2)) -eq 0 ]; then
		let n=$c+1
		if [[ $c -eq 0 ]]; then
			pattern=""
		else
                        pattern="$pattern & "
		fi
        	pattern="$pattern\${val[$c]} \${fill[$n]}(\${val[$n]})"
        fi
done

# For user convenience: add ${ } syntax automatically if not already present and if ! occurs at the beginning of the pattern
if [[ $userpattern -eq 1 ]]; then
        if [[ $patternconvenience -eq 1 ]]; then
                pattern=$(echo "$2" | sed 's/\(val\|fill\)\[\([0-9]*\)\]/\$\{\1\[\2\]\}/g')
                echo -e "Applying the following pattern (after preprocessing): $pattern\n" >&2
        else
                pattern=$2
                echo -e "Applying the following pattern: $pattern\n" >&2
        fi
else
                echo -e "Applying the following pattern: $pattern\n" >&2
fi

# create table header
if [[ $createheader -eq 1 ]]; then
        if [[ $conf != "" ]]; then
                echo "Found configuration string which can be used as table header: $conf" >&2
	fi

	# generate header
	echo -e "\\\\begin{table}[t]"
	echo -e "\t\\\\scriptsize"
	echo -e "\t\\\\centering"
        echo -e "\t%\\\\rowcolors{2}{white}{gray!25}"
	latexcols=$(echo $pattern | grep -o "&" | wc -l)
	let latexcols=$latexcols+1

	# check if the table contains information about the configurations
	if [[ $conf != "" ]]; then
		# extract the information
		conf=$(echo $conf | cut -d':' -f2)
		origIFS=$IFS
		IFS=';' read -a confs <<< "$conf"
	        for (( c=0; c < $latexcols; c++ ))
        	do
			if [[ $c -eq 1 ]]; then
				coldef="$coldef|$coldef"
			fi
	                coldef="${coldef}r"
			if [[ $c -gt 0 ]]; then
				colsep="$colsep & "
			fi

			# remove quotes from start and end
			confs[$c]=$(echo ${confs[$c]} | sed 's/^\"//' | sed 's/\"$//')

			# do we need a verbatim environment?
			if [[ $(echo ${confs[$c]} | sed 's/[[:alnum:]]//g') != "" ]]; then
				colsep="$colsep\\\\verb+${confs[$c]}+"
			else
	        	        colsep="$colsep${confs[$c]}"
			fi
		done
		IFS=$origIFS
	else
		# no information: create default header
                for (( c=0; c < $latexcols; c++ ))
                do
                        if [[ $c -eq 1 ]]; then
                                coldef="$coldef|$coldef"
                        fi
                        coldef="${coldef}r"
                        if [[ $c -gt 0 ]]; then
                                colsep="$colsep & "
                        fi
			colsep="${colsep}conf$c"
		done
	fi

	echo -e "\t\\\\begin{tabular}[t]{$coldef}"
	echo -e "\t\t\\\\$toprule"
	echo -e "\t\t$colsep \\\\\\\\"
	echo -e "\t\t\\\\$midrule"
	indent="\t\t"
fi

# create table body
echo -e "$file" | while read -r line
do
	val=($line)
        for ((c=0; c<${#val[@]}; c++))
        do
		fill[$c]=""
	        len=$(echo -ne ${val[$c]} | wc -c)
		for (( i=$len; i < ${max[$c]}; i++ ))
		do
			fill[$c]="${fill[$c]}~~"
		done
        done
	pateval="echo \"$pattern\""
	result=`eval $pateval`
	echo -e "$indent$result \\\\\\\\"
done

if [[ $# -ge 1 ]]; then
	echo -e "\t\t\\\\$bottomrule"
	echo -e "\t\\\\end{tabular}"
	echo -e "\t\\\\caption{${captionprefix}Benchmark Results}"
	echo -e "\t\\\\label{tab:$label}"
	echo -e "\\\\end{table}"
fi
