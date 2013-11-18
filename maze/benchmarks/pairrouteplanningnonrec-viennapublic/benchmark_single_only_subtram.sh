# $1: instance
# $2: timeout
export PATH=$1
export LD_LIBRARY_PATH=$2
instance=$3
to=$4
frumpy="--restarts=x,100,1.5 --deletion=1,75 --del-init-r=200,40000 --del-max=400000 --del-algo=basic --contraction=250 --loops=common --save-p=180 --del-grow=1.1 --strengthen=local"

confstr="route_strongsafety.hex vienna-publictransport.hex maxchanges.hex;--liberalsafety route.hex;--liberalsafety route.hex maxchanges.hex"
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
	mc=$(echo "((${instance:6:3} + 1) * 1.5 + 0.5) / 1" | bc)	# computation of max changes
	if [[ $mc == 0 ]]; then
		echo "" > $dir/$instance.$i.mc
	else
		echo "maxchanges($(echo "($mc + (${instance:6:3} + 1) * 2 - 2)" | bc ))." > $dir/$instance.$i.mc
	fi
	cmd="timeout $to time -o $dir/$instance.$i.time.dat -f %e dlvhex2 --claspconfig=\"$frumpy\" $c --plugindir=../../src --extlearn --evalall -n=1 map_only_subtram.hex $dir/$instance.$i.mc $dir/$instance --verbose=8 --silent"
	$($cmd 2>$dir/$instance.$i.verbose.dat >$dir/$instance.$i.out.dat)
	ret=$?
	cd instances
	output=$(cat $dir/$instance.$i.time.dat)
	if [[ $ret == 0 ]]; then
		output=$(cat $dir/$instance.$i.time.dat)
		groundertime=$(cat $dir/$instance.$i.verbose.dat | grep -a "HEX grounder time:" | tail -n 1 | grep -P -o '[0-9]+\.[0-9]+s' | sed "s/s//")
		solvertime=$(cat $dir/$instance.$i.verbose.dat | grep -a "HEX solver time:" | tail -n 1 | grep -P -o '[0-9]+\.[0-9]+s' | sed "s/s//")
		pathexists=$(cat $dir/$instance.$i.out.dat | wc -l)
		pathlen=$(cat $dir/$instance.$i.out.dat | sed 's/{//' | sed 's/}//' | sed 's/),/),\n/g' | grep "^orderedpath(" | cut -d"," -f 5 | sed 's/^/.+/' | bc | tail -1)
		pathlen=$(echo -e "$pathlen\n.+0" | bc | tail -1)
		changes=$(cat $dir/$instance.$i.out.dat | sed 's/{//' | sed 's/}//' | sed 's/),/),\n/g' | grep "^path(" | grep "change" | wc -l)
		restaurant=$(cat $dir/$instance.$i.out.dat | sed 's/{//' | sed 's/}//' | sed 's/),/),\n/g' | grep "^needRestaurant" | wc -l)
		pathexists=$(echo "$pathexists.00")
		pathlen=$(echo "$pathlen.00")
		changes=$(echo "$changes.00")
		restaurant=$(echo "$restaurant.00")
	else
        	output="---"
  	        groundertime="---"
	        solvertime="---"
		pathexists="---"
		pathlen="---"
		changes="---"
		restaurant="---"
	fi
	echo -ne "$output $groundertime $solvertime $pathexists $pathlen $changes $restaurant"

	cd $dir
	rm $dir/$instance.$i.time.dat
	rm $dir/$instance.$i.out.dat
	rm $dir/$instance.$i.verbose.dat
	rm $dir/$instance.$i.mc
	let i=i+1
done
echo -e -ne "\n"

