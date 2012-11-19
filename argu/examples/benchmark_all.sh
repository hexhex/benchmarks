# $1: confstr
# $2: timeout

if [ $# -le 0 ]; then
	confstr="--solver=genuinegc --flpcheck=explicit -n=1;--solver=genuinegc --flpcheck=explicit -n=1 --extlearn"
else
	confstr=$1
fi
if [ $# -le 1 ]; then
	to=300
else
	to=$2
fi

cd argubenchmark
for instance in *.argu
do
#	echo "
#		Executable = ../benchmark_single.sh
#		Universe = vanilla
#		output = $instance.out
#		error = $instance.error
#		Log = $instance.log
#		Requirements = machine == "node3.kr.tuwien.ac.at"
#		request_memory = 4096 
#		Initialdir = /mnt/lion/home/redl/hexhex_dlvhex/mcsieplugin/examples/argubenchmark/
#		notification = never
#
#		# queue
#		request_cpus = 1 
#		Arguments = $instance "$confstr" $to
#		Queue 1
#	     " > p.job
#	condor_submit p.job
	../benchmark_single.sh $instance "$confstr" $to
done

