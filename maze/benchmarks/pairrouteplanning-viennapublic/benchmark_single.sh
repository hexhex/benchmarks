# $1: instance
# $2: timeout
export PATH=$1
export LD_LIBRARY_PATH=$2
instance=$3
to=$4

confstr="--liberalsafety route.hex" #;route_strongsafety.hex vienna-publictransport2.hex"
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
	cmd="timeout $to time -o $dir/$instance.$i.time.dat -f %e dlvhex2 $c --plugindir=../../src --extlearn --evalall -n=1 $dir/$instance --heuristics=easy --verbose=8"
	$($cmd 2>$dir/$instance.$i.verbose.dat >/dev/null)
	ret=$?
	cd instances
	output=$(cat $dir/$instance.time.dat)
	if [[ $ret == 0 ]]; then
		output=$(cat $dir/$instance.$i.time.dat)
		groundertime=$(cat $dir/$instance.$i.verbose.dat | grep -a "HEX grounder time:" | tail -n 1 | grep -P -o '[0-9]+\.[0-9]+s' | sed "s/s//")
		solvertime=$(cat $dir/$instance.$i.verbose.dat | grep -a "HEX solver time:" | tail -n 1 | grep -P -o '[0-9]+\.[0-9]+s' | sed "s/s//")
	else
        	output="---"
  	        groundertime="---"
	        solvertime="---"
	fi
	echo -ne "$output $groundertime $solvertime"

	cd $dir
	rm $dir/$instance.time.dat
	rm $dir/$instance.$i.verbose.dat
	let i=i+1
done
echo -e -ne "\n"

