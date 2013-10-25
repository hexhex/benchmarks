for ((p=1; p<=2; p++))
do
	echo "person($p)."
	inst=$(echo "initlocation($p,Name) :- stop(ID, Type, Diva, Name, District, DistrictID, Lat, Lon, Date)." | dlvhex2 --silent --filter=initlocation stops.hex -- | sed 's/{//' | sed 's/,initlocation/.\ninitlocation/g' | sed 's/}/./' | sort -R | head -n $1)
	echo $inst | sed 's/\. /\.\n/g'
	echo $inst | sed 's/\. /\.\n/g' | head -n 1 | sed "s/initlocation($p,/sequence($p,0, /"
done

possiblemeetinglocations=$(echo "possiblemeetinglocations(Name) :- stop(ID, Type, Diva, Name, District, DistrictID, Lat, Lon, Date)." | dlvhex2 --silent --filter=possiblemeetinglocations stops.hex -- | sed 's/{//' | sed 's/,possiblemeetinglocations/.\npossiblemeetinglocations/g' | sed 's/}/./' | sort -R | head -n $1)
echo $possiblemeetinglocations | sed 's/\. /\.\n/g'
