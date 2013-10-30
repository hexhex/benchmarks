inst=$(echo "
	initlocation(Name) :-	stop(StopID, Type, Diva, Name, District, DistrictID, StopLat, StopLon, StopDate),
				line(LineID, LineName, Sequence, Realtime, \"ptTram\", LineDate),
				platform(PlatformID, LineID, StopID, Direction, PlatformSequence, RBLNr, Area, Platform, PlatformLat, PlatformLon, PlatformDate).
        initlocation(Name) :-   stop(StopID, Type, Diva, Name, District, DistrictID, StopLat, StopLon, StopDate),
                                line(LineID, LineName, Sequence, Realtime, \"ptMetro\", LineDate),
                                platform(PlatformID, LineID, StopID, Direction, PlatformSequence, RBLNr, Area, Platform, PlatformLat, PlatformLon, PlatformDate).
        initlocation(Name) :-   stop(StopID, Type, Diva, Name, District, DistrictID, StopLat, StopLon, StopDate),
                                line(LineID, LineName, Sequence, Realtime, \"ptTrainS\", LineDate),
                                platform(PlatformID, LineID, StopID, Direction, PlatformSequence, RBLNr, Area, Platform, PlatformLat, PlatformLon, PlatformDate)." \
	| dlvhex2 --silent --filter=initlocation stops.hex lines.hex platforms.hex -- | sed 's/{//' | sed 's/,initlocation/.\ninitlocation/g' | sed 's/}/./' | sort -R | head -n $1)
echo $inst | sed 's/\. /\.\n/g'
echo $inst | sed 's/\. /\.\n/g' | head -n 1 | sed 's/initlocation(/sequence(0, /'

restaurants=$(echo "
        restaurant(Name) :-   stop(StopID, Type, Diva, Name, District, DistrictID, StopLat, StopLon, StopDate),
                                line(LineID, LineName, Sequence, Realtime, \"ptTram\", LineDate),
                                platform(PlatformID, LineID, StopID, Direction, PlatformSequence, RBLNr, Area, Platform, PlatformLat, PlatformLon, PlatformDate).
        restaurant(Name) :-   stop(StopID, Type, Diva, Name, District, DistrictID, StopLat, StopLon, StopDate),
                                line(LineID, LineName, Sequence, Realtime, \"ptMetro\", LineDate),
                                platform(PlatformID, LineID, StopID, Direction, PlatformSequence, RBLNr, Area, Platform, PlatformLat, PlatformLon, PlatformDate).
        restaurant(Name) :-   stop(StopID, Type, Diva, Name, District, DistrictID, StopLat, StopLon, StopDate),
                                line(LineID, LineName, Sequence, Realtime, \"ptTrainS\", LineDate),
                                platform(PlatformID, LineID, StopID, Direction, PlatformSequence, RBLNr, Area, Platform, PlatformLat, PlatformLon, PlatformDate)." \
	| dlvhex2 --silent --filter=restaurant stops.hex lines.hex platforms.hex -- | sed 's/{//' | sed 's/,restaurant/.\nrestaurant/g' | sed 's/}/./' | sort -R | head -n $1)
echo $restaurants | sed 's/\. /\.\n/g'
