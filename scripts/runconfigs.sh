# This script generates output after execution of a given command under various configurations with timeout.

if [ $# != 4 ] && [ $# != 5 ]; then
	echo "This script expects 4 or 5 parameters"
	echo " $1: Command for executing an instance, which may constain the constant CONF as a placeholder for options to be inserted and INST as a placeholder for the instance"
	echo " $2: ;-separated configuration strings to be inserted for CONF in $1"
	echo " $3: Instance to be inserted in the command string at position INST"
	echo " $4: Timeout"
	echo " $5: [optional] Custom output builder name of a script to build the output of a run, which gets the parameters"
	echo "	$1: return value of command (0 if success, 124 if timeout, != 0 if failed)"
	echo "	$2: file with stdout of command"
	echo "	$3: file with stderr of command"
	echo ""
	echo " Return value:"
	echo "	0 if execution of the script was successful (not necessarily the actual instance)"
	echo "	1 if the benchmark script itself failed"
	exit 1
fi

command=$1
confstr=$2
instance=$3
to=$4
outputbuilder="$(dirname $0)/timeoutputbuilder.sh"
if [ $# == 5 ]; then
	outputbuilder=$5
fi

# split configurations
IFS=';' read -ra confs <<< "$confstr;"
header="#instance"
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
timefile=$(mktemp)
stdoutfile=$(mktemp)
stderrfile=$(mktemp)
i=0

for c in "${confs[@]}"
do
	echo -ne -e " "

	# prepare command
	fullcommand=${command/CONF/$c}
	fullcommand=${fullcommand/INST/$instance}
	cmd="timeout $to time -o $timefile -f %e $fullcommand"

	# execute
	$($cmd >$stdoutfile 2>$stderrfile)
	ret=$?

	# build output
	output=$($outputbuilder $ret $timefile $stdoutfile $stderrfile)
	obresult=$?
	if [ $obresult -eq 0 ]; then
		echo -ne $output
	elif [ $obresult -eq 2 ]; then
		echo "Error during execution of: \"$fullcommand\"" >&2
		echo ">> Stdout:" >&2
		cat $stdoutfile >&2
		echo ">> Stderr:" >&2
		cat $stderrfile >&2
		echo -ne $output
	else
		echo "Output builder for command \"$fullcommand\" failed" >&2
		exit 1
	fi

	let i=i+1
done
echo -e -ne "\n"
rm $timefile
rm $stdoutfile
rm $stderrfile
