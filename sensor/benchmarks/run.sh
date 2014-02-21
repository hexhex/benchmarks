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
	echo "       \$4: directory with the benchmark scripts" >&2
	echo "       \$5: (optional) timeout, default is 300" >&2
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
	else
		runinstsdir=$(which runinsts.sh | head -n 1)
		if [ -e "$runinstsdir" ]; then
			bmscripts=$(dirname "$runinstsdir")
		fi
	fi
else
	instance=$2
	to=$3
	bmscripts=$4
fi
if ! [ -e "$bmscripts" ]; then
	echo "Could not find benchmark scripts"
	exit 1
fi

# run instances
mydir="$(dirname $0)"
mydir=$(cd $mydir; pwd)

if [[ $all -eq 1 ]]; then
	# run all instances using the benchmark script run insts
	$bmscripts/runinsts.sh "instances/*.asp" "$mydir/run.sh" "$mydir" "$to"
else
	# run single instance
	confstr="--flpcheck=explicit --noflpcriterion;--flpcheck=explicit --extlearn --noflpcriterion;--flpcheck=ufsm --noflpcriterion;--flpcheck=ufsm --extlearn --noflpcriterion;--flpcheck=ufsm --extlearn --ufslearn --noflpcriterion;--flpcheck=ufs;--flpcheck=ufs --extlearn;--flpcheck=ufs --extlearn --ufslearn;--flpcheck=aufs;--flpcheck=aufs --extlearn;--flpcheck=aufs --extlearn --ufslearn;--flpcheck=aufs --extlearn --ufslearn --ufscheckheuristics=periodic;--flpcheck=aufs --extlearn --ufslearn --ufscheckheuristics=max;--flpcheck=explicit --noflpcriterion -n=1;--flpcheck=explicit --noflpcriterion --extlearn -n=1;--flpcheck=ufsm -n=1;--flpcheck=ufsm --extlearn --noflpcriterion -n=1;--flpcheck=ufsm --extlearn --ufslearn --noflpcriterion -n=1;--flpcheck=ufs -n=1;--flpcheck=ufs --extlearn -n=1;--flpcheck=ufs --extlearn --ufslearn -n=1;--flpcheck=aufs -n=1;--flpcheck=aufs --extlearn -n=1;--flpcheck=aufs --extlearn --ufslearn -n=1;--flpcheck=aufs --extlearn --ufslearn --ufscheckheuristics=periodic -n=1;--flpcheck=aufs --extlearn --ufslearn --ufscheckheuristics=max -n=1"

	# make sure that the encodings are found
	$bmscripts/runconfigs.sh "dlvhex2 --claspconfig=none --plugindir=../src CONF domain_anyobjectposition.hex $mydir/INST" "$confstr" "$instance" "$to"
fi

