#!/bin/bash

# $1: condor or sequential
# $1: instance loop condition
# $2: single benchmark command
# $3: working directory
# $4: timeout
# $5: custom aggregation script
# $6: Name of the benchmark
# $7: requirements file

if [[ $# -gt 7 ]]; then
	error=1
fi
qm="?"
if [[ $# -eq 1 ]] && [ $1 == $qm ]; then
	error=1
fi

if [[ $error -eq 1 ]]; then
	echo "This script needs 0 to 5 parameters:" 1>&2
	echo " \$1: (optional) Instance loop condition (default: *.hex)" 1>&2
        echo " \$2: (optional) Single benchmark command (default: ./run.sh)" 1>&2
        echo " \$3: (optional) Working directory (default: PWD)" 1>&2
	echo " \$4: (optional) Timeout (default: 300)" 1>&2
        echo " \$5: (optional) Custom aggregation script (default: ./aggregateresults.sh)" 1>&2
	echo " \$6: (optional) Name of the benchmark (default: name of the working directory)" 1>&2
        echo " \$7: (optional) Requirements file" 1>&2
	echo "" 1>&2
	echo "The script will pass 4 parameters to the single benchmark command:" 1>&2
	echo " \$1: single" 1>&2
	echo " \$2: Instance name" 1>&2
	echo " \$3: Timeout" 1>&2
	echo " \$4: Directory which contains the benchmark scripts (directory of this script)" 1>&2
	echo "" 1>&2
	echo "Template for a run.sh script:" 1>&2
	echo "      ./runconfigs.sh \"dlvhex2 INST\"" "--solver=genuinegc;--solver=genuineii\" $3 $4" 1>&2
	echo "" 1>&2
	echo "Template for a Condor HT req file (see req_template):" 1>&2
	echo "      Universe = vanilla" 1>&2
	echo "      Requirements = machine == \"lion.kr.tuwien.ac.at\"" 1>&2
	echo "      request_memory = 8192" 1>&2
	echo "If the req file contains the string \"sequential\" (without quotes)," 1>&2
	echo "then all instances will be executed in sequence (see reqseq)." 1>&2
	echo "If the req file contains a line of form" 1>&2
	echo "#	    ExtendedNotification = mail@address.com" 1>&2
	echo "the benchmark results will be sent per mail to you (if mail is configured)" 1>&2
	echo "" 1>&2
	echo "The script will execute all instances and aggregate their results" 1>&2
	echo "in a table called \"results_$1.dat\"" 1>&2
	exit 1
fi

helperscriptdir="$(dirname $0)"

# default parameters
if [[ $# -ge 1 ]] && [[ $1 != "" ]]; then
        loop=$1
else
        loop="*.hex"
fi
if [[ $# -ge 2 ]] && [[ $2 != "" ]]; then
        cmd=$2
else
        cmd="./run.sh"
fi
if [[ $# -ge 3 ]] && [[ $3 != "" ]]; then
        workingdir=$3
else
        workingdir=$PWD
fi
workingdir=$(cd $workingdir; pwd)
if [[ $# -ge 4 ]] && [[ $4 != "" ]]; then
        to=$4
else 
        to=300
fi
if [[ $# -ge 5 ]] && [[ $5 != "" ]]; then
        aggscript=$5
else 
        aggscript=$helperscriptdir/aggregateresults.sh
fi
if [[ $# -ge 6 ]] && [[ $6 != "" ]]; then
	benchmarkname=$6
else
	benchmarkname=$(cd $workingdir; pwd)
	benchmarkname=$(basename $benchmarkname)
fi

# check if there is a requirements file
# priorities: 1. command-line parameter, 2. directory of single benchmark script, 3. directory of this script
if [[ $# -ge 7 ]] && [[ $7 != "" ]]; then
	# consider it as relative path wrt. the working directory
	reqfile=$workingdir/$7
        requirements=$(cat $reqfile 2> /dev/null)
	if [ $? -ne 0 ]; then
		# consider it as relative path wrt. the bmscripts directory
		reqfile=$(dirname $0)/$7
                requirements=$(cat $reqfile 2> /dev/null)
		if [ $? -ne 0 ]; then
			# consider $7 as absolute path
			reqfile=$7
	                requirements=$(cat $reqfile 2> /dev/null)
			if [ $? -ne 0 ]; then
				echo "Requirements file $reqfile not found" 1>&2
				exit 1
			fi
		fi
	fi
else
	# check working directory
	reqfile=$workingdir/req
        requirements=$(cat $reqfile 2> /dev/null)
	if [ $? -ne 0 ]; then
		# check bmscripts directory
		reqfile=$(dirname $0)/req
		requirements=$(cat $reqfile 2> /dev/null)
		if [ $? -ne 0 ]; then
			echo "Requirements file not found" 1>&2
			exit 1
		fi
	fi
fi

# interpret requirements
echo "=== Running benchmark \"$benchmarkname\"" 1>&2
requirements=$(cat "$reqfile")
sequential=$(echo $requirements | grep "sequential" | wc -l)
if [[ $sequential -eq 0 ]]; then  
	echo -e "Requirements:" 1>&2
	requirements=$(echo -e "$requirements" | sed 's/^/                   /')
	echo -e "$requirements"
	sequential=0

	extnotification=$(echo -e "$requirements" | grep -i "extendednotification" | wc -l)
	if [[ $extnotification -gt 0 ]]; then
		notification=2
		extnotification=$(echo -e "$requirements" | grep -i "extendednotification" | cut -d'=' -f2)
        elif [[ $(echo $requirements | grep -i "notification" | grep -i "never" | wc -l) -eq 1 ]]; then
                notification=0
	else
		notification=1
	fi

	noexecution=0
        noexecution=$(echo -e "$requirements" | grep -i "noexecution" | wc -l)
        if [[ $noexecution -gt 0 ]]; then
                noexecution=1
        fi
else
	echo "Sequential mode" 1>&2
	sequential=1
fi
forceoverwrite=0
forceoverwrite=$(echo -e "$requirements" | grep -i "forceoverwrite" | wc -l)
if [[ $forceoverwrite -gt 0 ]]; then
	forceoverwrite=1
fi
outputdir=$(echo -e "$requirements" | grep -i "outputdir" | cut -d'=' -f2)
if [[ $outputdir == "" ]]; then
	outputdir="$workingdir/$benchmarkname.output"
fi
newbmname=$(echo -e "$requirements" | grep -i "benchmarkname" | cut -d'=' -f2)
if [[ $newbmname != "" ]]; then
	benchmarkname=$newbmname
fi

# print summary
echo "" 1>&2
echo "Loop:              $loop" 1>&2
echo "Command:           $cmd" 1>&2
echo "Working directory: $workingdir" 1>&2
echo "Timeout:           $to" 1>&2
echo "Requirements file: $reqfile" 1>&2
echo "Output directory:  $outputdir" 1>&2

# Make sure that the output directory exists
if [ -e "$outputdir" ]; then
        echo "Output directory $outputdir already exists, type \"del\" to confirm overwriting"
        read inp
        if [[ $inp != "del" ]]; then
                echo "Will NOT overwrite the existing directory. Aborting benchmark execution!"
                exit 1
        fi
        rm -r $outputdir
fi
mkdir -p $outputdir
outputdir=$(cd $outputdir; pwd)

# schedule all instances
cd $workingdir
for instance in $(eval "echo $loop")
do
	# make sure that the output directory exists
	mkdir -p $outputdir/$instance
	rmdir $outputdir/$instance

	echo "Instance $instance:" 1>&2
	echo "   cd $workingdir" 1>&2
	echo "   $cmd single \"$instance\" \"$to\" \"$helperscriptdir\"" 1>&2
	if [ $sequential -eq 0 ]; then
		# prepare single jobs
		echo "
			Executable = $cmd
			Output = $outputdir/$instance.out
			Error = $outputdir/$instance.error
			Log = $outputdir/$instance.log
			$requirements
			Initialdir = $workingdir
			Notification = never
			getenv = true

			# queue
			Arguments = single $instance $to $helperscriptdir
			Queue 1
		     " > $outputdir/$instance.job
		dagman="${dagman}Job InstJob${instance} $outputdir/${instance}.job\n"
		instjobs="$instjobs InstJob${instance}"
	else
		echo "Calling: $cmd single \"$instance\" \"$to\" \"$helperscriptdir\" >$outputdir/$instance.out 2>$outputdir/$instance.error" >&2
		$cmd single "$instance" "$to" "$helperscriptdir" >$outputdir/$instance.out 2>$outputdir/$instance.error
		cat $outputdir/$instance.out
		cat $outputdir/$instance.error >&2
	fi
	resultfiles="$resultfiles $outputdir/$instance.out"
done
if [ $sequential -eq 0 ]; then
	# prepare a script which outputs the benchmark name as a comment and eliminates duplicate comments from the out files
	echo -e "	echo \"# Benchmark:$benchmarkname\"
			cat \$* | grep \"#\" | uniq
			cat \$* | grep -v \"#\"" > $outputdir/allout.sh
			chmod a+x $outputdir/allout.sh
	
        echo -e "
                        Executable = $outputdir/allout.sh
                        Output = $outputdir/allout.dat
                        Error = $outputdir/allout.err
                        Log = $outputdir/allout.log
                        $requirements
                        Initialdir = $outputdir
                        Notification = never
                        getenv = true

                        # queue
                        Arguments = $resultfiles 
                        Queue 1
                " > $outputdir/allout.job

	# prepare a job for aggregation of the results
	echo -e "
			Executable = $aggscript
			Output = $outputdir/$benchmarkname.dat
			Error = $outputdir/$benchmarkname.err
			Log = $outputdir/$benchmarkname.log
			Input = $outputdir/allout.dat
			$requirements
			Initialdir = $workingdir
			Notification = never
			getenv = true

			# queue
			Arguments = $to
			Queue 1
		" > $outputdir/agg.job

	# prepare condor command according to desired notification behavior
	if [[ $notification -eq 2 ]]; then
        	condorcmd="condor_submit_dag -autorescue 1 -maxjobs 10 -maxidle 50 -notify never"	# we have an extended notification anyway

	        echo -e "
        	                Executable = $(dirname $0)/sendnotification.sh 
                	        Output = $outputdir/notify.stdout 
                        	Error = $outputdir/notify.err
	                        Log = $outputdir/notify.log
                	        $requirements
                        	Initialdir = $(dirname $0)
	                        Notification = never
        	                getenv = true

                	        # queue
                        	Arguments = $benchmarkname $extnotification 0 Results 1 $outputdir/$benchmarkname.dat 0 Path 0 $outputdir 0 Details 1 $outputdir/allout.dat
	                        Queue 1
                " > $outputdir/notify.job

                echo "Will send an EXTENDED e-mail notification including results when the benchmark completes (if mail is configured)"
       	elif [[ $notification -eq 1 ]]; then
        	condorcmd="condor_submit_dag -autorescue 1 -maxjobs 10 -maxidle 50"
                echo "Will send an e-mail notification when the benchmark completes (if mail configured)"
        else
		condorcmd="condor_submit_dag -autorescue 1 -maxjobs 10 -maxidle 50 -notify never"
                echo "Will NOT send an e-mail notification when the benchmark completes"
        fi


	# acutally submit them
	echo -e "
			$dagman
			Job AlloutJob $outputdir/allout.job
			Job AggJob $outputdir/agg.job
			PARENT $instjobs CHILD AlloutJob
			PARENT AlloutJob CHILD AggJob
		" > "$outputdir/$benchmarkname.dag"
	if [[ $notification -eq 2 ]]; then
		echo "	Job NotificationJob $outputdir/notify.job
			PARENT AggJob CHILD NotificationJob
			" >> "$outputdir/$benchmarkname.dag"
	fi
	if [[ $noexecution -eq 0 ]]; then
		$condorcmd $outputdir/$benchmarkname.dag
		if [ $? -ne 0 ]; then
			echo "Error while scheduling benchmark \"$benchmarkname\" for execution" >&2
			exit 1
		fi
	        echo "Benchmark \"$benchmarkname\" scheduled for execution" 1>&2
	else
		echo "Benchmark \"$benchmarkname\" prepared but not executed" >&2
	fi
else
	# aggregate results
	if [[ $resultfiles != "" ]]; then
		echo "Aggregating results in file $outputdir/$benchmarkname.dat" 1>&2
		rerrfile=$(mktemp)
		echo "" > $outputdir/$benchmarkname.dat
		cat $resultfiles | $aggscript $to >$outputdir/$benchmarkname.dat 2>$outputdir/$benchmarkname.err
		if [[ $? -ne 0 ]]; then
			echo "Aggregation failed" >> $outputdir/$benchmarkname.dat
			echo "Input to R:" >> $outputdir/$benchmarkname.dat
			echo $resultfiles >> $outputdir/$benchmarkname.dat
			echo "Error output from R:" >> $outputdir/$benchmarkname.dat
			echo $outputdir/$benchmarkname.err >> $outputdir/$benchmarkname.dat
		fi
		rm $rerrfile
	else
		echo "" > "$outputdir/$benchmarkname.dat"
	fi
	echo "Benchmark \"$benchmarkname\" finished" 1>&2
fi
