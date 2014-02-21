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
	echo "This script expects 0, 1, 2, 4 or 5 parameters" >&2
	echo "   \$1: (optional) \"all\" or \"single\", default is \"all\"" >&2
	echo "   (a) If \$1=\"all\" then there are no further parameters" >&2
	echo "       \$2: (optional) timeout, default is 300" >&2
	echo "   (b) If \$1=\"single\" then" >&2
	echo "       \$2: instance name" >&2
	echo "       \$3: timeout in seconds" >&2
	echo "       \$4: directory with the benchmark scripts" >&2
	echo "       \$5: (optional) timeout, default is 300" >&2
	exit 1
fi

# set default values
if [[ $# -eq 0 ]]; then
	all=1
elif [[ $1 == "all" ]]; then
	all=1
else
	all=0
fi

# get location of benchmark scripts
if [[ $DLVHEX_BENCHMARKSCRIPTS != "" ]]; then
	bmscripts=$DLVHEX_BENCHMARKSCRIPTS

	if [[ $# == 2 ]]; then
		to=$2
	elif [[ $# == 5 ]]; then
		to=$2
	else
		to=300
	fi
fi
if [[ $all -eq 0 ]]; then
	instance=$2
	to=$3
	bmscripts=$4
fi
if [[ $bmscripts == "" ]]; then
	echo "Warning: Location of benchmark scripts not found; set variable DLVHEX_BENCHMARKSCRIPTS."
fi

# run instances
mydir="$(dirname $0)"
if [[ $all -eq 1 ]]; then
	# run all instances using the benchmark script run insts
	$bmscripts/runinsts.sh "instances/*.hex" "$mydir/run.sh" "$mydir" "$to"
else
	# run single instance
	confstr="--solver=genuinegc;--solver=genuineii"
	$bmscripts/runconfigs.sh "dlvhex2 --plugindir=../../src INST CONF" "$confstr" "$instance" "$to"
fi

