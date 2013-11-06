# $1: instance
# $2: timeout
export PATH=$1
export LD_LIBRARY_PATH=$2
instance=$3
to=$4

confstr="route_strongsafety.hex vienna-publictransport.hex;--liberalsafety route.hex"
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
	cmd="timeout $to time -o $dir/$instance.$i.time.dat -f %e dlvhex2 $c --plugindir=../../src --extlearn --evalall -n=1 map_only_subtram.hex $dir/$instance --verbose=8 --silent"
	$($cmd 2>$dir/$instance.$i.verbose.dat >$dir/$instance.$i.out.dat)
	ret=$?
	cd instances
	output=$(cat $dir/$instance.$i.time.dat)
	if [[ $ret == 0 ]]; then
		output=$(cat $dir/$instance.$i.time.dat)
		groundertime=$(cat $dir/$instance.$i.verbose.dat | grep -a "HEX grounder time:" | tail -n 1 | grep -P -o '[0-9]+\.[0-9]+s' | sed "s/s//")
		solvertime=$(cat $dir/$instance.$i.verbose.dat | grep -a "HEX solver time:" | tail -n 1 | grep -P -o '[0-9]+\.[0-9]+s' | sed "s/s//")
		pathlen=$(cat $dir/$instance.$i.out.dat | sed 's/{//' | sed 's/}//' | sed 's/),/),\n/g' | grep "^orderedpath(" | cut -d"," -f 5 | sed 's/^/.+/' | bc | tail -1)
		pathlen=$(echo -e "$pathlen\n.+0" | bc | tail -1)
		changes=$(cat $dir/$instance.$i.out.dat | sed 's/{//' | sed 's/}//' | sed 's/),/),\n/g' | grep "^path(" | grep "change" | wc -l)
		restaurant=$(cat $dir/$instance.$i.out.dat | sed 's/{//' | sed 's/}//' | sed 's/),/),\n/g' | grep "^needRestaurant" | wc -l)
		pathlen=$(echo "$pathlen.00")
		changes=$(echo "$changes.00")
		restaurant=$(echo "$restaurant.00")
	else
        	output="---"
  	        groundertime="---"
	        solvertime="---"
		pathlen="---"
		changes="---"
		restaurant="---"
	fi
	echo -ne "$output $groundertime $solvertime $pathlen $changes $restaurant"

	cd $dir
	rm $dir/$instance.$i.time.dat
	rm $dir/$instance.$i.out.dat
	rm $dir/$instance.$i.verbose.dat
	let i=i+1
done
echo -e -ne "\n"

