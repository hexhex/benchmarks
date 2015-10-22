#!/bin/bash

runheader=$(which run_header.sh)
if [[ $runheader == "" ]] || [ $(cat $runheader | grep "run_header.sh Version 1." | wc -l) == 0 ]; then
        echo "Could not find run_header.sh (version 1.x); make sure that the benchmark scripts directory is in your PATH"
        exit 1
fi
source $runheader

# run instances
if [[ $all -eq 1 ]]; then
	# run all instances using the benchmark script run insts
	$bmscripts/runinsts.sh "instances/*.argu" "$mydir/run.sh" "$mydir" "$to" "" "" "$req"
else
	# run single instance
	confstr="--extlearn=none;--extlearn;--welljustified;--extlearn =none -n=1;--extlearn -n=1;--welljustified -n=1"

	# make sure that the encodings are found
	cd ../../src
	$bmscripts/runconfigs.sh "dlvhex2 --claspconfig=none --plugindir=. --argumode=idealset CONF $mydir/INST" "$confstr" "$instance" "$to"
fi

