confstr="--solver=genuinegc --eaevalheuristics=immediate --heuristics=asp:../src/evalheur.asp --extlearn;--solver=genuinegc --eaevalheuristics=immediate --heuristics=asp:../src/evalheur.asp"
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

# for all argu files
for instance in sudokus/*.hex
do
	echo -ne $instance

	# for all configurations
	for c in "${confs[@]}"
	do
		echo -ne -e " "

		output=$(timeout 300 time -f %e dlvhex2 $c --plugindir=../src $instance 2>&1 >/dev/null)
		if [[ $? == 124 ]]; then
			output="---"
		fi
		echo -ne $output

		# make sure that there are no zombies
		pkill -9 -u $USER dlvhex2
		pkill -9 -u $USER dlv
	done
	echo -e -ne "\n"
done
