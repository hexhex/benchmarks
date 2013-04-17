# $1: instance
# $2: timeout
export PATH=$1
export LD_LIBRARY_PATH$2
instance=$3
to=$4

confstr="--extlearn --flpcheck=aufs --heuristics=monolithic --liberalsafety;--extlearn --flpcheck=aufs --heuristics=greedy --liberalsafety"

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
	cd ../../../src
	cmd="timeout $to time -o $dir/$instance.time.dat -f %e dlvhex2 $c --plugindir=. --argumode=idealset $dir/$instance --verbose=8"
	output=$($cmd 2>$dir/$instance.verbose.dat >/dev/null)

	ret=$?
        output=$(cat $dir/$instance.time.dat)
	groundertime=$(cat $dir/$instance.verbose.dat | grep -a "HEX grounder time:" | tail -n 1 | grep -P -o '[0-9]+\.[0-9]+s' | sed "s/s//")
        solvertime=$(cat $dir/$instance.verbose.dat | grep -a "HEX solver time:" | tail -n 1 | grep -P -o '[0-9]+\.[0-9]+s' | sed "s/s//")

    	if [[ $ret == 124 ]]; then
        	output="---"
  	        groundertime="---"
	        solvertime="---"
	fi
	echo -ne "$output $groundertime $solvertime"

	cd $dir
	let i=i+1
done
echo -e -ne "\n"

rm $dir/$instance.time.dat
rm $dir/$instance.verbose.dat
