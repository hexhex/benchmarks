# merged benchmark tables line-wise
if [[ $# == 0 ]]
then
	exit 0
fi

cmd="paste $1"
for (( i=2; i<=$#; i++ ))
do
	cmd="$cmd <(cat ${!i} | cut -d\" \" -f3-)"
done
eval $cmd
