# $1: instance
# $2: timeout

export LD_LIBRARY_PATH=/mnt/lion/home/redl/local/lib
export PATH=$PATH:/mnt/lion/home/redl/local/bin

confstr="--solver=genuinegc --flpcheck=explicit -n=1;--solver=genuinegc --flpcheck=explicit -n=1 --extlearn"

# default parameters
if [ $# -le 1 ]; then
	echo "Error: invalid parameters"
	exit 1
else
	instance=$1
	to=$2
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
echo -ne "$instance "

# for all configurations
i=0
for c in "${confs[@]}"
do
	echo -ne -e " "
	dir=$PWD
	cd ../../src
	cmd="timeout $to time -f %e dlvhex2 $c --plugindir=. --argumode=idealset $dir/$instance"
	output=$($cmd 2>&1 >/dev/null)
	if [[ $? == 124 ]]; then
		output="---"
	fi
	cd $dir
	echo -ne $output
	let i=i+1
done
echo -e -ne "\n"

