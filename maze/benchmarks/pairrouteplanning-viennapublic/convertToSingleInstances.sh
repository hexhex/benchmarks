for file in instances/*.hex
do
	cat $file | sed 's/initlocation(1,/initlocation(/' | sed 's/initlocation(2,/initlocation2(/' | sed 's/sequence(1,/sequence(/' | sed 's/sequence(2,/sequence2/' \
		| grep -v "person" | grep -v "initlocation2" | grep -v "sequence2" | grep -v "possiblemeetinglocation" > $1/$file
done
