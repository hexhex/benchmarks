while read line
do
	out=$(echo $line | sed 's/{orderedpath(\([0-9]*\),/\1,/g' | sed 's/)}//g' | sed 's/),orderedpath(\([0-9]*\),/\n\1,/g' | sort -n)
	persons=$(echo -e "$out" | cut -f1 -d"," | uniq)
	echo -e "$persons" | while read person
	do
		echo "Route for person $person"
		# sed 's/\(\w\),\([[:space:]]\)/\1\2/g'
		echo -e "$out" | grep "^$person" | sed "s/$person,//" | sed 's/, / /g' | sort -n | sed 's/[0-9]*,\"//' | sed 's/\"//g' | sed 's/\([^,]*\),\([^,]*\),\([^,]*\),change/[\3] Change from \1 to \2/' | sed 's/\([^,]*\),\([^,]*\),\([^,]*\),\([^,]*\)/[\3] Go \1 ---> \2 by \4/'
	done
done
