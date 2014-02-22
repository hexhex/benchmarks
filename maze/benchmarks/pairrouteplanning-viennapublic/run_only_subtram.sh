#!/bin/bash

runheader=$(which dlvhex_run_header.sh)
if [[ $runheader == "" ]] || [ $(cat $runheader | grep "dlvhex_run_header.sh Version 1." | wc -l) == 0 ]; then
	echo "Could not find dlvhex_run_header.sh (version 1.x); make sure that the benchmarks/script directory is in your PATH"
	exit 1
fi
source $runheader

# run instances
map="map_only_subtram.hex"
if [[ $all -eq 1 ]]; then
	# run all instances using the benchmark script run insts
	$bmscripts/runinsts.sh "instances/*.hex" "$mydir/run.sh" "$mydir" "$to" "$mydir/aggregate.sh" "$map" "$req"
else
	# run single instance
	confstr="route_strongsafety.hex vienna-publictransport.hex maxchanges.hex;--liberalsafety route.hex;--liberalsafety route.hex maxchanges.hex"
	frumpy="--restarts=x,100,1.5 --deletion=1,75 --del-init-r=200,40000 --del-max=400000 --del-algo=basic --contraction=250 --loops=common --save-p=180 --del-grow=1.1 --strengthen=local"

	# computation of max changes
	instancefn=$(basename $instance)
	mc=$(echo "((${instance:6:3} + 1) * 1.5 + 0.5) / 1" | bc)
	if [[ $mc == 0 ]]; then
		echo "" > $instance.mc
	else
		echo "maxchanges($(echo "($mc + (${instancefn:6:3} + 1) * 2 - 2)" | bc ))." > $instance.mc
	fi

	$bmscripts/runconfigs.sh "dlvhex2 --claspconfig=\"$frumpy\" $c --plugindir=../../src --extlearn --evalall -n=1 --verbose=8 --silent CONF $map $instance.mc" "$confstr" "$instance" "$to" "$mydir/outputbuilder.sh"

	rm $instance.mc
fi

