for ((p=1; p<=2; p++))
do
	echo "person($p)."
	inst=$(echo "
        initlocation($p,Name) :-   stop(StopID, Type, Diva, Name, District, DistrictID, StopLat, StopLon, StopDate),
                                line(LineID, LineName, Sequence, Realtime, \"ptMetro\", LineDate),
                                platform(PlatformID, LineID, StopID, Direction, PlatformSequence, RBLNr, Area, Platform, PlatformLat, PlatformLon, PlatformDate).
        initlocation($p,Name) :-   stop(StopID, Type, Diva, Name, District, DistrictID, StopLat, StopLon, StopDate),
                                line(LineID, LineName, Sequence, Realtime, \"ptTrainS\", LineDate),
                                platform(PlatformID, LineID, StopID, Direction, PlatformSequence, RBLNr, Area, Platform, PlatformLat, PlatformLon, PlatformDate).
        initlocation($p,Name) :-   stop(StopID, Type, Diva, Name, District, DistrictID, StopLat, StopLon, StopDate),
                                line(LineID, LineName, Sequence, Realtime, \"ptTram\", LineDate),
                                platform(PlatformID, LineID, StopID, Direction, PlatformSequence, RBLNr, Area, Platform, PlatformLat, PlatformLon, PlatformDate).
	" | dlvhex2 --silent --filter=initlocation stops.hex lines.hex platforms.hex -- | sed 's/{//' | sed 's/,initlocation/.\ninitlocation/g' | sed 's/}/./' | sort -R | head -n $1)
	echo $inst | sed 's/\. /\.\n/g'
	echo $inst | sed 's/\. /\.\n/g' | head -n 1 | sed "s/initlocation($p,/sequence($p,0, /"
done

possiblemeetinglocations=$(echo "
        possiblemeetinglocations(Name) :-   stop(StopID, Type, Diva, Name, District, DistrictID, StopLat, StopLon, StopDate),
                                line(LineID, LineName, Sequence, Realtime, \"ptMetro\", LineDate),
                                platform(PlatformID, LineID, StopID, Direction, PlatformSequence, RBLNr, Area, Platform, PlatformLat, PlatformLon, PlatformDate).
        possiblemeetinglocations(Name) :-   stop(StopID, Type, Diva, Name, District, DistrictID, StopLat, StopLon, StopDate),
                                line(LineID, LineName, Sequence, Realtime, \"ptTrainS\", LineDate),
                                platform(PlatformID, LineID, StopID, Direction, PlatformSequence, RBLNr, Area, Platform, PlatformLat, PlatformLon, PlatformDate).
        possiblemeetinglocations(Name) :-   stop(StopID, Type, Diva, Name, District, DistrictID, StopLat, StopLon, StopDate),
                                line(LineID, LineName, Sequence, Realtime, \"ptTram\", LineDate),
                                platform(PlatformID, LineID, StopID, Direction, PlatformSequence, RBLNr, Area, Platform, PlatformLat, PlatformLon, PlatformDate).
	" | dlvhex2 --silent --filter=possiblemeetinglocations stops.hex lines.hex platforms.hex -- | sed 's/{//' | sed 's/,possiblemeetinglocations/.\npossiblemeetinglocations/g' | sed 's/}/./' | sort -R | head -n $1)
echo $possiblemeetinglocations | sed 's/\. /\.\n/g'

restaurants=$(echo "
        restaurant(Name) :-   stop(StopID, Type, Diva, Name, District, DistrictID, StopLat, StopLon, StopDate),
                                line(LineID, LineName, Sequence, Realtime, \"ptMetro\", LineDate),
                                platform(PlatformID, LineID, StopID, Direction, PlatformSequence, RBLNr, Area, Platform, PlatformLat, PlatformLon, PlatformDate).
        restaurant(Name) :-   stop(StopID, Type, Diva, Name, District, DistrictID, StopLat, StopLon, StopDate),
                                line(LineID, LineName, Sequence, Realtime, \"ptTrainS\", LineDate),
                                platform(PlatformID, LineID, StopID, Direction, PlatformSequence, RBLNr, Area, Platform, PlatformLat, PlatformLon, PlatformDate).
        restaurant(Name) :-   stop(StopID, Type, Diva, Name, District, DistrictID, StopLat, StopLon, StopDate),
                                line(LineID, LineName, Sequence, Realtime, \"ptTram\", LineDate),
                                platform(PlatformID, LineID, StopID, Direction, PlatformSequence, RBLNr, Area, Platform, PlatformLat, PlatformLon, PlatformDate).
	" | dlvhex2 --silent --filter=restaurant stops.hex lines.hex platforms.hex -- | sed 's/{//' | sed 's/,restaurant/.\nrestaurant/g' | sed 's/}/./' | sort -R | head -n $1)
echo $restaurants | sed 's/\. /\.\n/g'
