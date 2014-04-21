#! /bin/bash

# A typical example call is
# 	multibenchmark.sh benchmarks.def $PWD/140225 $PWD/req
# where benchmarks.def contains
# 	setminus=~/dlvhex/core/benchmarks/setminus/run.sh
# 	argu=~/dlvhex/benchmarks/argu/benchmarks/ufs/run.sh

if [[ $# -lt 3 ]] || [[ $# -gt 4 ]] || [ ! -e $1 ] || [ ! -e $3 ]; then
        error=1;
fi
if [[ $# -ge 4 ]] && [ ! -e $4 ]; then
	error=1;
fi

if [[ $error -eq 1 ]]; then
	echo "Expects as input" 2>&1
	echo "  \$1: File with lines of form BENCHMARKNAME=PATH," >&2
	echo "       where PATH is expected to point to a run.sh script" >&2
	echo "       If the directory of run.sh does also contain a compare.sh script, then this script" >&2
	echo "       is used for comparing benchmark tables; it gets the current results \$1 and the reference results \$2" >&2
	echo "       and is expected to return 0 if there is no significant difference, 2 if there is a significant difference, and 1 on other errors." >&2
	echo "  \$2: Output directory for the overall benchmark results; is expected to contain a requirements file called metareq" >&2
	echo "  \$3: Requirements file" >&2
	echo "  \$4: (optional) Either script to be executed after benchmarks have been finished; working directory will be \$2," >&2
	echo "       or directory with reference results" >&2
	echo "After completion of all benchmarks, \$4 will be called (if existing); it gets the names of all benchmarks as parameters" >&2
	exit 1
fi

specification=$1
outputdir=$2
req=$3
if [ -e $outputdir ]; then
        echo "Output directory $outputdir already exists, type \"del\" to confirm overwriting"
        read inp
        if [[ $inp != "del" ]]; then
                echo "Will NOT overwrite the existing directory. Aborting benchmark execution!"
                exit 1
        fi
        rm -r $outputdir
fi
mkdir -p $outputdir
# use default comparison script if required
if [[ $# -ge 4 ]] && [[ $4 != "" ]]; then
	if [ -d $4 ]; then
		mail=$(cat $req | grep -i "extendednotification" | cut -d'=' -f2)
		echo "	mail=$mail
			for (( i=1; i<=\$#; i++ ))
			do
	        		echo \"Copying reference file from $4/\${!i}/\${!i}.dat to \${!i}/\${!i}.ref\"
			cp $4/\${!i}/\${!i}.dat \${!i}/\${!i}.ref
			done
			source compare.sh" >> $outputdir/final.sh
		chmod a+x $outputdir/final.sh
		finalscript=$outputdir/final.sh
	else
		finalscript=$4
	fi
fi

# prepare all benchmarks
while read line
do
	bmname=$(echo $line | cut -d'=' -f1)
	runscript=$(echo $line | cut -d'=' -f2)
	cat $req > $outputdir/metareq_$bmname
	echo "getenv = true" >>$outputdir/metareq_$bmname
	echo "# NoExecution" >>$outputdir/metareq_$bmname
	echo "# OutputDir=$outputdir/$bmname" >> $outputdir/metareq_$bmname
	echo "# BenchmarkName=$bmname" >> $outputdir/metareq_$bmname
	$runscript "all" "" "" "$outputdir/metareq_$bmname"
        if [ $? -ne 0 ]; then
                echo "Execution of $runscript yielded an error; aborting" >&2
                exit 1
        fi

        rundir=$(dirname $runscript)
        echo "Checking if there is a compare script in $rundir"
        cp $rundir/compare.sh $outputdir/$bmname/compare.sh

	echo "" >> $outputdir/multibenchmark.dag
	echo "SUBDAG EXTERNAL $bmname $outputdir/$bmname/$bmname.dag" >> $outputdir/multibenchmark.dag
	allbenchmarks="$allbenchmarks $bmname"

	# set parameters
	condor_submit_dag -no_submit -maxjobs 10 -maxidle 50 -notification never $outputdir/$bmname/$bmname.dag
done < $specification

# prepare final job
if [[ $finalscript != "" ]]; then
	cat $req > $outputdir/final.job
	echo "
        	Executable = $finalscript
	        Output = $outputdir/multibenchmark.out
        	Error = $outputdir/multibenchmark.error
	        Log = $outputdir/multibenchmark.log
		Universe = vanilla
	        Initialdir = $outputdir
        	Notification = never
	        getenv = true

        	# queue
	        Arguments = $allbenchmarks
        	Queue 1
		" >> $outputdir/final.job

	# final script after completion of all benchmarks
	echo "Job Final $outputdir/final.job
		PARENT $allbenchmarks CHILD Final
		" >> $outputdir/multibenchmark.dag
fi

echo "Starting all benchmarks" >&2
condor_submit_dag -maxjobs 10 -maxidle 50 -notification never $outputdir/multibenchmark.dag

