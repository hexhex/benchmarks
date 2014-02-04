# merged benchmark tables line-wise
if [[ $# == 0 ]]
then
	exit 0
fi

cmd="paste -d ' '"
for (( i=1; i<=$#; i++ ))
do
	if [[ $i -ge 2 ]]; then
		cmd="$cmd <(cat ${!i} | sed 's/^ *//g' | sed 's/ \+/ /g' | cut -d\" \" -f3-)"
	else
                cmd="$cmd <(cat ${!i} | sed 's/^ *//g' | sed 's/ \+/ /g' | cut -d\" \" -f1-)"
	fi
done
eval $cmd
