cd original

cd preprocessing
for f in *.qdimacs
do
	../../convert2qbf.py --mode=sum $f > ../../disjunctionencoding/preprocessing/$f.tmp
	../../f-aggregates.py -g $PWD/../../gringo ../../disjunctionencoding/preprocessing/$f.tmp > ../../disjunctionencoding/preprocessing/$f
	rm ../../disjunctionencoding/preprocessing/$f.tmp
        ../../convert2qbf.py --mode=agg $f > ../../hex/preprocessing/$f
#	exit 0
done
