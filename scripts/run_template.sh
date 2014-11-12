#!/bin/bash

# This file serves as a template for run scripts for new benchmarks.
# Most of the script may be left unchanged. The parts which depend
# on the current benchmark are marked.
#
# If your PATH variable contains the path to a clone of
# https://github.com/hexhex/benchmarks/scripts,
# then the benchmarks can be started by calling
#	./run.sh
# Otherwise, you may explicitly specify the path by calling
#	./run.sh all 300 PATH_TO_BENCHMARK_SCRIPTS
#
# In many cases, run scripts will be exactly like this template until the
# very last if block (*). Thus they may simply include this part,
# provided in file dlvhex_run_header.sh and continue with
# an adopted version of block (*), as follows:	
#
# 	runheader=$(which dlvhex_run_header.sh)
# 	if [[ $runheader == "" ]] || [ $(cat $runheader | grep "dlvhex_run_header.sh Version 1." | wc -l) == 0 ]; then
# 		echo "Could not find dlvhex_run_header.sh (version 1.x); make sure that the benchmarks/script directory is in your PATH"
# 		exit 1
# 	fi
# 	source $runheader
#
#	[adopted block (*)]
#
# Note: The scripts output some additional information to stderr,
#       which should be redirected to /dev/null unless you are debugging.

# check input validity
inputok=1
if [[ $# -eq 0 ]]; then
	inputok=1
elif [[ $1 != "" ]] && [[ $1 != "all" ]] && [[ $1 != "allseq" ]] && [[ $1 != "single" ]]; then
	inputok=0
elif [[ $1 == "single" ]] && [[ $# -lt 3 ]]; then
	inputok=0
fi
if [[ $inputok -eq 0 ]]; then
	echo "This script expects 0 to 5 parameters" >&2
	echo "   \$1: (optional) \"all\", \"allseq\" or \"single\", default is \"all\"" >&2
	echo "   (a) If \$1=\"all\" then there are no further mandatory parameters" >&2
	echo "       \$2: (optional) timeout, default is 300" >&2
	echo "       \$3: (optional) directory with the benchmark scripts" >&2
	echo "   (b) If \$1=\"allseq\" then there are no further mandatory parameters" >&2
	echo "       \$2: (optional) timeout, default is 300" >&2
	echo "       \$3: (optional) directory with the benchmark scripts" >&2
	echo "       This will execute all instances sequentially (Condor HT is not used)" >&2
	echo "   (c) If \$1=\"single\" then" >&2
	echo "       \$2: instance name" >&2
	echo "       \$3: timeout in seconds" >&2
	echo "       \$4: (optional) directory with the benchmark scripts" >&2
	exit 1
fi

# set default values
# and get location of benchmark scripts
if [[ $# -eq 0 ]]; then
	all=1
elif [[ $1 == "" ]]; then
        all=1
elif [[ $1 == "all" ]]; then
	all=1
elif [[ $1 == "allseq" ]]; then
	all=1
	req="reqseq"
else
	all=0
fi
if [[ $all -eq 1 ]]; then
	if [[ $# -ge 2 ]] && [[ $2 != "" ]]; then
		to=$2
	else
		to=300
	fi
	if [[ $# -ge 3 ]]; then
		bmscripts=$3
	fi
else
	instance=$2
	to=$3
	if [[ $# -ge 4 ]]; then
		bmscripts=$4
	fi
fi
if [[ $bmscripts == "" ]]; then
	runinstsdir=$(which runinsts.sh | head -n 1)
	if [ -e "$runinstsdir" ]; then
		bmscripts=$(dirname "$runinstsdir")
	fi
fi
if ! [ -e "$bmscripts" ]; then
	echo "Could not find benchmark scripts"
	exit 1
fi

# get directory where this script is executed from
mydir="$(dirname $0)"
mydir=$(cd $mydir; pwd)

#
# (*)
# 
# HERE THE BENCHMARK-SPECIFIC PART STARTS
if [[ $all -eq 1 ]]; then
	# ============================================================
	# Replace "instances/*.hex" in (1) by the loop condition
	# to be used for iterating over the instances
	# ============================================================

	# run all instances using the benchmark script runinsts.sh
	$bmscripts/runinsts.sh "instances/*.hex" "$mydir/run.sh" "$mydir" "$to"                             # (1)

	# In order to use a custom aggregation script "myagg.sh" (in the same directory as run.sh)
	# and/or a custom benchmark name "bmname", use:
	# $bmscripts/runinsts.sh "instances/*.hex" "$mydir/run.sh" "$mydir" "$to" "$mydir/agg.sh" "bmname"  # (1 [alternative])
else
	# ============================================================
	# Define the variable "confstr" in (2) as a semicolon-
	# separated list of configurations to compare.
	# In (3) replace "dlvhex2 --plugindir=../../src INST CONF"
	# by an appropriate call of dlvhex, where INST will be
	# substituted by the instance file and CONF by the current
	# configuration from variable "confstr".
	# ============================================================

	# run single instance
	confstr="--solver=genuinegc;--solver=genuineii"                                                                    # (2)
	$bmscripts/runconfigs.sh "dlvhex2 --plugindir=../../src INST CONF" "$confstr" "$instance" "$to"                    # (3)

	# In order to use a custom output builder "myob.sh" (in the same directory as run.sh), use:
	# $bmscripts/runconfigs.sh "dlvhex2 --plugindir=../../src INST CONF" "$confstr" "$instance" "$to" "$mydir/myob.sh" # (3 [alternative])
fi

