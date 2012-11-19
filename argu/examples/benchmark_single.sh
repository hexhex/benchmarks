# $1: instance
# $2: confstr
# $3: timeout

# default parameters
if [ $# -le 2 ]; then
	echo "Error: invalid parameters"
	exit 1
else
	instance=$1
	confstr=$2
	to=$3
fi

# split configurations
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

# do benchmark
echo -ne "$instance "

# for all configurations
i=0
for c in "${confs[@]}"
do
	echo -ne -e " "
	# if a configuration timed out, then it can be skipped for larger instances
	if [ ${timeout[$i]} -eq 0 ]; then
		dir=$PWD
		cd ../../src
		cmd="timeout 300 time -f %e dlvhex2 $c --plugindir=. --argumode=idealset $dir/$instance"
		output=$($cmd 2>&1 >/dev/null)
		if [[ $? == 124 ]]; then
			output="---"
			timeout[$i]=1
		fi
		cd $dir
	else
		output="---"
	fi
	echo -ne $output
	let i=i+1
done
echo -e -ne "\n"

