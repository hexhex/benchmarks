# $1: instance
# $2: timeout
export PATH=$1
export LD_LIBRARY_PATH=$2
instance=$3
to=$4

confstr=" "
confstr2=$(cat ../conf)
if [ $? == 0 ]; then
        confstr=$confstr2
fi

# split configurations
IFS=';' read -ra confs <<< "$confstr"
header="#size"
i=0
for c in "${confs[@]}"
do
	header="$header   \"$c\""
	let i=i+1
done
echo $header

# do benchmark
echo -ne "$instance"

# for all configurations
i=0
for c in "${confs[@]}"
do
	echo -ne -e " "
	dir=$PWD
	cd ..
	cmd="timeout $to time -o $dir/$instance.time.dat -f %e dlvhex2 $c --plugindir=../../src --extlearn --evalall --liberalsafety -n=1 gas.hex $dir/$instance"
	$($cmd 2>/dev/null >/dev/null)
	ret=$?
	cd instances
	output=$(cat $dir/$instance.time.dat)
	if [[ $ret != 0 ]]; then
		output="---"
	fi
	cd $dir
	echo -ne $output
	rm $dir/$instance.time.dat
	let i=i+1
done
echo -e -ne "\n"

