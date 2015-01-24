#!/bin/bash

runheader=$(which dlvhex_run_header.sh)
if [[ $runheader == "" ]] || [ $(cat $runheader | grep "dlvhex_run_header.sh Version 1." | wc -l) == 0 ]; then
	echo "Could not find dlvhex_run_header.sh (version 1.x); make sure that the benchmarks/script directory is in your PATH"
	exit 1
fi
source $runheader

# run instances
if [[ $all -eq 1 ]]; then
	# run all instances using the benchmark script run insts
	$bmscripts/runinsts.sh "instances/*.argu" "$mydir/run.sh" "$mydir" "$to" "" "" "$req"
else
	# run single instance
	confstr="--flpcheck=explicit --extlearn=none --flpcriterion=head;--flpcheck=explicit --extlearn --flpcriterion=head;--flpcheck=ufsm --extlearn=none --ufslearn=none --flpcriterion=head;--flpcheck=ufsm --extlearn --ufslearn=none --flpcriterion=head;--flpcheck=ufsm --extlearn --ufslearn --flpcriterion=head;--flpcheck=ufs --extlearn=none --ufslearn=none;--flpcheck=ufs --extlearn --ufslearn=none;--flpcheck=ufs --extlearn --ufslearn;--flpcheck=aufs --extlearn=none;--flpcheck=aufs --extlearn --ufslearn=none;--flpcheck=aufs --extlearn --ufslearn;--flpcheck=aufs --extlearn --ufslearn --ufscheckheuristics=periodic;--flpcheck=aufs --extlearn --ufslearn --ufscheckheuristics=max;--flpcheck=explicit --extlearn=none --flpcriterion=head -n=1;--flpcheck=explicit --extlearn --flpcriterion=head -n=1;--flpcheck=ufsm --extlearn=none --ufslearn=none -n=1;--flpcheck=ufsm --extlearn --ufslearn=none --flpcriterion=head -n=1;--flpcheck=ufsm --extlearn --ufslearn --flpcriterion=head -n=1;--flpcheck=ufs --extlearn=none --ufslearn=none -n=1;--flpcheck=ufs --extlearn --ufslearn=none -n=1;--flpcheck=ufs --extlearn --ufslearn -n=1;--flpcheck=aufs --extlearn=none --ufslearn=none -n=1;--flpcheck=aufs --extlearn --ufslearn=none -n=1;--flpcheck=aufs --extlearn --ufslearn --ufslearn=none -n=1;--flpcheck=aufs --extlearn --ufslearn --ufscheckheuristics=periodic -n=1;--flpcheck=aufs --extlearn --ufslearn --ufscheckheuristics=max -n=1"

	# make sure that the encodings are found
	cd ../../src
	$bmscripts/runconfigs.sh "dlvhex2 --claspconfig=none --claspinverseliterals --plugindir=. --argumode=idealset CONF $mydir/INST" "$confstr" "$instance" "$to"
fi

