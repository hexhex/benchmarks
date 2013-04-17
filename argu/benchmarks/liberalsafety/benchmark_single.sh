# $1: instance
# $2: timeout

export LD_LIBRARY_PATH=/mnt/lion/home/redl/local/lib
export PATH=$PATH:/mnt/lion/home/redl/local/bin

confstr="--flpcheck=explicit;--flpcheck=explicit --extlearn;--flpcheck=ufsm --noflpcriterion;--flpcheck=ufsm --extlearn --noflpcriterion;--flpcheck=ufsm --extlearn --ufslearn --noflpcriterion;--flpcheck=ufs;--flpcheck=ufs --extlearn;--flpcheck=ufs --extlearn --ufslearn;--flpcheck=aufs;--flpcheck=aufs --extlearn;--flpcheck=aufs --extlearn --ufslearn;--flpcheck=explicit -n=1;--flpcheck=explicit --extlearn -n=1;--flpcheck=ufsm -n=1;--flpcheck=ufsm --extlearn --noflpcriterion -n=1;--flpcheck=ufsm --extlearn --ufslearn --noflpcriterion -n=1;--flpcheck=ufs -n=1;--flpcheck=ufs --extlearn -n=1;--flpcheck=ufs --extlearn --ufslearn -n=1;--flpcheck=aufs -n=1;--flpcheck=aufs --extlearn -n=1;--flpcheck=aufs --extlearn --ufslearn -n=1"

# default parameters
if [ $# -le 1 ]; then
	echo "Error: invalid parameters"
	exit 1
else
	instance=$1
	to=$2
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
echo -ne "$instance "

# for all configurations
i=0
for c in "${confs[@]}"
do
	echo -ne -e " "
	dir=$PWD
	cd ../../src
	cmd="timeout $to time -f %e dlvhex2 $c --plugindir=. --argumode=idealset $dir/$instance"
	output=$($cmd 2>&1 >/dev/null)
	if [[ $? == 124 ]]; then
		output="---"
	fi
	cd $dir
	echo -ne $output
	let i=i+1
done
echo -e -ne "\n"

