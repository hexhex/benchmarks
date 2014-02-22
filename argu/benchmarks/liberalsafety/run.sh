#!/bin/bash

source dlvhex_run_header.sh

# run instances
if [[ $all -eq 1 ]]; then
	# run all instances using the benchmark script run insts
	$bmscripts/runinsts.sh "instances/*.argu" "$mydir/run.sh" "$mydir" "$to"
else
	# run single instance
	confstr="--extlearn --flpcheck=aufs --heuristics=monolithic --liberalsafety;--extlearn --flpcheck=aufs --heuristics=greedy --liberalsafety"

	# make sure that the encodings are found
	cd ../../src
	$bmscripts/runconfigs.sh "dlvhex2 --plugindir=. --argumode=idealset CONF $mydir/INST" "$confstr" "$instance" "$to"
fi

