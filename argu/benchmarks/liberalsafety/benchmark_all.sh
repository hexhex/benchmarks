# $1: timeout

if [ $# -le 1 ]; then
	to=300
else
	to=$1
fi

cd argubenchmark
for instance in *.argu
do
	echo "
		Executable = ../benchmark_single.sh
		Universe = vanilla
		output = $instance.out
		error = $instance.error
		Log = $instance.log
		Requirements = machine == \"lion.kr.tuwien.ac.at\"
		request_memory = 4096 
		Initialdir = $PWD
		notification = never

		# queue
		request_cpus = 1 
		Arguments = $instance $to
		Queue 1
	     " > p.job
	condor_submit p.job
#	./../benchmark_single.sh $instance $to
done

