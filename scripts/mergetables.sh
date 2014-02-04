# merged benchmark tables line-wise
if [[ $# == 0 ]]
then
	exit 0
fi

cmd="paste -d ' '"
for (( i=1; i<=$#; i++ ))
do
	cmd="$cmd <(cat ${!i} | sed 's/^ *//g' | sed 's/ \+/ /g' | cut -d\" \" -f3-)"
done
eval $cmd
