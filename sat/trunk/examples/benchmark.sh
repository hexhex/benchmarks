#function strlen() { echo -n ${#1}; }

#function tab() {
#	s="";
#	for (( i = $1; i < $2; i++))
#	do
#		s="$s "
#	done
#	echo -ne $s;
#}

confstr="--solver=genuinegc;--solver=genuinegc --extlearn"
IFS=';' read -ra confs <<< "$confstr"
header="#size"
i=0
for c in "${confs[@]}"
do
	timeout[$i]=0
	header="$header   \"$c\""
	let i=i+1
done
echo $header

# get length of longest instance name
#len=0
#for instance in *.dimacs
#do
#	l=`strlen $instance`
#	if [[ $l -gt $len ]]; then
#		len=$l
#	fi
#done
#echo $len

# for all dimacs files
for instance in *.dimacs
do
	echo -ne $instance
#	tab `strlen $instance` $len

	mode="sat";
	if [[ "$instance" == *"unsat"* ]]; then
		mode="unsat";
	fi

	# for all configurations
	for c in "${confs[@]}"
	do
		echo -ne -e " "
		output=$(timeout 3 time -f %e dlvhex2 $c --plugindir=../src/ --satunsatmode=$mode $instance 2>&1 >/dev/null)
		if [[ $? == 124 ]]; then
			output="---"
		fi
		echo -ne $output
	done
	echo -e -ne "\n"
done
