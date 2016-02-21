cd original
for f in *.asp
do
	f-aggregates.py $f ../disjunctionencoding/kcc.asp > ../disjunctionencoding/$f
done
