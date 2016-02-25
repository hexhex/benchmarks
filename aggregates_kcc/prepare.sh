cd original
for f in *.asp
do
	../f-aggregates.py -g $PWD/../gringo $f ../disjunctionencoding/kcc.asp > ../disjunctionencoding/$f
done
