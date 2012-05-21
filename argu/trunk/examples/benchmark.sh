confstr="--solver=genuinegc --flpcheck=explicit;--solver=genuinegc --flpcheck=ufs"
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
for instance in argubenchmark/*.argu
do
	echo -ne $instance

	# for all configurations
	for c in "${confs[@]}"
	do
		echo -ne -e " "
		dir=$PWD
		cd ../src
		cmd="timeout 120 time -f %e /tmp/newinstrelease/bin/dlvhex2 $c --plugindir=. --argumode=idealset --nocache $dir/$instance"
    #echo -e "\n$cmd\n"
		output=$($cmd 2>&1 >/dev/null)
		if [[ $? == 124 ]]; then
			output="---"
		fi
		cd $dir
		echo -ne $output

		# make sure that there are no zombies
		#pkill -9 -u $USER dlvhex2
		#pkill -9 -u $USER dlv
	done
	echo -e -ne "\n"
done
