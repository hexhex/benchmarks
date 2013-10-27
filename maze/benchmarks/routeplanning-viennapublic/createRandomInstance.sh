inst=$(echo "initlocation(Name) :- stop(ID, Type, Diva, Name, District, DistrictID, Lat, Lon, Date)." | dlvhex2 --silent --filter=initlocation stops.hex -- | sed 's/{//' | sed 's/,initlocation/.\ninitlocation/g' | sed 's/}/./' | sort -R | head -n $1)
echo $inst | sed 's/\. /\.\n/g'
echo $inst | sed 's/\. /\.\n/g' | head -n 1 | sed 's/initlocation(/sequence(0, /'

restaurants=$(echo "restaurant(Name) :- stop(ID, Type, Diva, Name, District, DistrictID, Lat, Lon, Date)." | dlvhex2 --silent --filter=restaurant stops.hex -- | sed 's/{//' | sed 's/,restaurant/.\nrestaurant/g' | sed 's/}/./' | sort -R | head -n $1)
echo $restaurants | sed 's/\. /\.\n/g'
