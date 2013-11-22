# $1: instance
# $2: timeout

# default parameters
export PATH=$1
export LD_LIBRARY_PATH=$2
instance=$3
to=$4

confstr="--flpcheck=explicit --noflpcriterion;--flpcheck=explicit --noflpcriterion --extlearn;--flpcheck=ufsm --noflpcriterion;--flpcheck=ufsm --extlearn --noflpcriterion;--flpcheck=ufsm --extlearn --ufslearn --noflpcriterion;--flpcheck=ufs;--flpcheck=ufs --extlearn;--flpcheck=ufs --extlearn --ufslearn;--flpcheck=aufs;--flpcheck=aufs --extlearn;--flpcheck=aufs --extlearn --ufslearn;--flpcheck=explicit --noflpcriterion -n=1;--flpcheck=explicit --noflpcriterion --extlearn -n=1;--flpcheck=ufsm -n=1;--flpcheck=ufsm --extlearn --noflpcriterion -n=1;--flpcheck=ufsm --extlearn --ufslearn --noflpcriterion -n=1;--flpcheck=ufs -n=1;--flpcheck=ufs --extlearn -n=1;--flpcheck=ufs --extlearn --ufslearn -n=1;--flpcheck=aufs -n=1;--flpcheck=aufs --extlearn -n=1;--flpcheck=aufs --extlearn --ufslearn -n=1"

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
echo -ne "$instance"

# for all configurations
i=0
for c in "${confs[@]}"
do
	echo -ne -e " "
	$(timeout $to time --quiet -o $instance.time.dat -f %e dlvhex2 $c --plugindir=../../src ../domain_anyobjectposition.hex $instance 2>/dev/null >/dev/null)
	ret=$?
	output=$(cat $instance.time.dat)
	if [[ $ret != 0 ]]; then
		output="---"
	fi
	echo -ne $output
	let i=i+1

	rm $instance.time.dat
done
echo -e -ne "\n"
