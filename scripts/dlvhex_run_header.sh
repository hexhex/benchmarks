#!/bin/bash

# dlvhex_run_header.sh Version 1.0		Do not remove or change this line!
#						This allows run scripts to detect that this is the proper run header file
#						Only the minor version may be changed, a change in the major version
#						makes existing scripts fail.

# check input validity
inputok=1
if [[ $# -eq 0 ]]; then
	inputok=1
elif [[ $# -gt 5 ]]; then
	inputok=0
elif [[ $1 != "all" ]] && [[ $1 != "single" ]]; then
	inputok=0
fi
if [[ $inputok -eq 0 ]]; then
	echo "This script expects 0 to 5 parameters" >&2
	echo "   \$1: (optional) \"all\" or \"single\", default is \"all\"" >&2
	echo "   (a) If \$1=\"all\" then there are no further parameters" >&2
	echo "       \$2: (optional) timeout, default is 300" >&2
	echo "       \$3: (optional) directory with the benchmark scripts" >&2
	echo "   (b) If \$1=\"single\" then" >&2
	echo "       \$2: instance name" >&2
	echo "       \$3: timeout in seconds" >&2
	echo "       \$4: (optional) directory with the benchmark scripts" >&2
	exit 1
fi

# set default values
# and get location of benchmark scripts
if [[ $# -eq 0 ]]; then
	all=1
elif [[ $1 == "all" ]]; then
	all=1
else
	all=0
fi
if [[ $all -eq 1 ]]; then
	if [[ $# -ge 2 ]]; then
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

