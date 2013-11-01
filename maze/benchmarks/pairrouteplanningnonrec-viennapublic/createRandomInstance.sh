st=$(echo "st(Name) :-   stop(ID, Type, Diva, Name, District, DistrictID, Lat, Lon, Date)." | dlvhex2 --silent --filter=st stops.hex -- | sed 's/{//' | sed 's/}/./' | sed 's/,st(/.\nst(/g')

for ((p=1; p<=2; p++))
do
	echo "person($p)."
	inst=$(echo -e "$st" | sed "s/st(/initlocation($p,/g" | sort -R | head -n $1)
	echo -e "$inst"
	echo -e "$inst" | head -n 1 | sed "s/initlocation($p,/sequence($p,0, /"
done

possiblemeetinglocations=$(echo -e "$st" | sed 's/st(/possiblemeetinglocations(/g' | sed 's/,possiblemeetinglocations/.\npossiblemeetinglocations/g' | sort -R | head -n $1)
echo -e "$possiblemeetinglocations"

restaurants=$(echo "$st" | sed 's/st(/restaurant(/g' | sed 's/,restaurant/.\nrestaurant/g' | sort -R | head -n $1)
echo -e "$restaurants"
