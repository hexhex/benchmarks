for (( argcount=$1; argcount <= $2; argcount+=$3 ))
do
	for (( edgeprop=$4; edgeprop <= $5; edgeprop+=$6 ))
	do
		for (( backedgeprop=$7; backedgeprop <= $8; backedgeprop+=$9 ))
		do
			for (( inst=0; inst < $10; inst++ ))
			do
				ep=`printf "%03d" ${edgeprop}`
				ac=`printf "%03d" ${argcount}`
				in=`printf "%03d" ${inst}`
				./generate.sh $argcount $edgeprop $backedgeprop > "arguinst_edgeprob_${ep}_argucount_${ac}_inst_${in}.argu"
			done
		done
	done
done
