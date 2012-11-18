# $1: argument count
# $2: edge propability
# $3: probability that for an edge (a,b) also edge (b,a) is added

prop=$((32768 * $2 / 100)) 
backprop=$((32768 * $3 / 100))
for (( i=1; i <= $1; i++ ))
do
	echo "arg($i)."

	for (( j = 1; j <= $1; j++ ))
	do
		if [ $RANDOM -le $prop ]; then
			echo "att($i,$j)."
			if [ $RANDOM -le $backprop ]; then
				echo "att($j,$i)."
			fi
		fi
	done
done
