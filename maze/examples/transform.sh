while read -r line
do
	if [[ $line == *NamedIndividual* ]]; then
		nr=$(echo $line | grep -P -o "[0-9]+")
	fi
	if [[ $line == *featurename* ]]; then
		fn=$(echo $line | grep -P -o ">.*</" | cut -c 2- | rev | cut -c 3- | rev)
		echo "name($nr, \"$fn\")."
	fi
	if [[ $line == *next* ]]; then
		nrn=$(echo $line | grep -P -o "[0-9]+")
		echo "next($nr, $nrn)."
	fi
done < $1
