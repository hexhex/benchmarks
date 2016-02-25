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
	$bmscripts/runinsts.sh "original/preprocessing/*.qdimacs" "$mydir/run.sh" "$mydir" "$to" "" "" "$req"
else
	# run single instance
	ci="disjunctionencoding/preprocessing/$(basename $instance)"
	hi="original/preprocessing/$(basename $instance)"
	confstr="clasp $ci;clasp -n 0 $ci;dlvhex2 --aggregate-mode=extbl --eaevalheuristics=always --claspdefernprop=0 --ngminimization=always -n=1 hex/kcc.hex $hi;dlvhex2 --aggregate-mode=extbl --eaevalheuristics=always --claspdefernprop=0 --ngminimization=always hex/kcc.hex $hi"

	$bmscripts/runconfigs.sh "CONF" "$confstr" "" "$to"
fi

