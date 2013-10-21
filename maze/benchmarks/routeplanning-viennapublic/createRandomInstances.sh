for ((size=3; size <= 10; size++))
do
	for ((i=1; i <= 10; i++))
	do
		fn=$(printf "s%03d_i%03d" $size $i)
		./createRandomInstance.sh $size > instances/inst_$fn.hex
	done
done
