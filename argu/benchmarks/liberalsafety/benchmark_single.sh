# $1: instance
# $2: timeout
export PATH=$1
export LD_LIBRARY_PATH=$2
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
	cmd="timeout $to time -o $dir/$instance.$i.time.dat -f %e dlvhex2 $c --plugindir=.:../../../core/testsuite --argumode=idealset $dir/$instance $dir/../aggregate.hex --verbose=8"
	output=$($cmd 2>$dir/$instance.$i.verbose.dat >/dev/null)
	ret=$?

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

	rm $dir/$instance.$i.time.dat
	rm $dir/$instance.$i.verbose.dat

	cd $dir
	let i=i+1
done
echo -e -ne "\n"
