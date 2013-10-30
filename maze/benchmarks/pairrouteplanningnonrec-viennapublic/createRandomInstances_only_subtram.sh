for ((size=1; size <= 15; size++))
do
	for ((i=1; i <= 50; i++))
	do
		fn=$(printf "s%03d_i%03d" $size $i)
		./createRandomInstance_only_subtram.sh $size > instances_only_subtram/inst_$fn.hex
	done
done
