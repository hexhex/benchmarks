# $1: timeout

if [ $# -le 0 ]; then
	to=300
else
	to=$1
fi

reqirements=$(cat req 2> /dev/null)
cd instances 
for instance in *.asp
do
	echo "
		Executable = ../benchmark_single.sh
		output = $instance.out
		error = $instance.error
		Log = $instance.log
		$requirements
		Initialdir = $PWD/
		notification = never

		# queue
		request_cpus = 1 
		Arguments = $PATH $LD_LIBRARY_PATH $instance $to
		Queue 1
	     " > p.job
	condor_submit p.job
done

