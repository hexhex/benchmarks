
//
// this include is necessary
//

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif /* HAVE_CONFIG_H */

#include <dlvhex2/ExternalLearningHelper.h>
#include <dlvhex2/PluginInterface.h>
#include <dlvhex2/ProgramCtx.h>
#include <dlvhex2/Term.h>
#include <dlvhex2/Registry.h>
#include <dlvhex2/Logger.h>
#include <dlvhex2/Printer.h>

// without that define it will not work
#define DLVHEX_BENCHMARK
#include <dlvhex2/Benchmarking.h>

#include <boost/geometry.hpp>
#include <boost/geometry/geometries/point_xy.hpp>
#include <boost/geometry/geometries/polygon.hpp>
#include <boost/geometry/algorithms/within.hpp> 
#include <boost/geometry/strategies/agnostic/point_in_poly_winding.hpp> 

#include <string>
#include <sstream>
#include <cstdio>
#include <cstdlib>
#include <cmath>

namespace geom = boost::geometry;

using namespace dlvhex;

namespace sensors
{

class SensorRangeCheck
{
public:
  virtual ~SensorRangeCheck() {}

  virtual bool canSee(float range, unsigned rx, unsigned ry, unsigned ox, unsigned oy)
  {
    LOG(INFO,"checking whether " << rx << "/" << ry << " can see " << ox << "/" << oy << " with range " << range);
    float dx = fabs(float(ox) - float(rx));
    float dy = fabs(float(oy) - float(ry));

    if( sqrtf(dx*dx + dy*dy) > range )
      return false;
    else
      return true;
  }
};

// obj or robot -> x/y
typedef std::map<ID, std::pair<ID,ID> > LocMap;
struct TimeLocMap
{
	// objects without time
	LocMap dobjects;

	// time -> objects
	std::map<ID, LocMap> objects;
	// time -> robots
	std::map<ID, LocMap> robots;
};
typedef std::set<ID> IDSet;

void extractObjectTerms(IDSet& o, ID objpred, RegistryPtr reg, InterpretationConstPtr pi) {
	// find relevant input
	bm::bvector<>::enumerator en = pi->getStorage().first();
	bm::bvector<>::enumerator en_end = pi->getStorage().end();
	while (en < en_end)
	{
		// id of current true bit
		ID id(ID::MAINKIND_ATOM | ID::SUBKIND_ATOM_ORDINARYG, *en);
		const OrdinaryAtom& atom = reg->ogatoms.getByID(id);
		if( atom.tuple.size() == 2 && atom.tuple[0] == objpred ) {
			o.insert(atom.tuple[1]);
			//relevantIDs.insert(id);
		}
		en++;
	}
}

bool extractTimeLoc(TimeLocMap& tlm, IDSet& relevantIDs, RegistryPtr reg, InterpretationConstPtr pi,
		const ID robotxpr, const ID robotypr, const ID objxpr, const ID objypr)
{
	// find relevant input
	bm::bvector<>::enumerator en = pi->getStorage().first();
	bm::bvector<>::enumerator en_end = pi->getStorage().end();
	while (en < en_end)
	{
		// id of current true bit
		ID id(ID::MAINKIND_ATOM | ID::SUBKIND_ATOM_ORDINARYG, *en);
		const OrdinaryAtom& atom = reg->ogatoms.getByID(id);
		if( atom.tuple.size() == 3 )
		{
			// {objectX,objectY}(Object,Coordinate)
			ID pred = atom.tuple[0];
			ID entity = atom.tuple[1];
			ID coordinate = atom.tuple[2];
			LOG(INFO,"got tuple " << printToString<RawPrinter>(id,reg));

			// refer -> if not exists, create empty ones
			LocMap &objLoc = tlm.dobjects;
			if( pred == objxpr || pred == objypr ) {
				// either robot x or y coordinate
				if( pred == objxpr ) {
					ID& objX = objLoc[entity].first;
					if( objX != ID_FAIL )
						// duplicate assignment -> abort
						return false;
					else
						objX = coordinate;
				}
				else {
					ID& objY = objLoc[entity].second;
					if( objY != ID_FAIL )
						// duplicate assignment -> abort
						return false;
					else
						objY = coordinate;
				}
				relevantIDs.insert(id);
			}
		}
		else if( atom.tuple.size() == 4 )
		{
			// {robotX,robotY,objectX,objectY}(Robot,Coordinate,Step)
			ID pred = atom.tuple[0];
			ID entity = atom.tuple[1];
			ID coordinate = atom.tuple[2];
			ID step = atom.tuple[3];
			LOG(INFO,"got tuple " << printToString<RawPrinter>(id,reg));

			if( pred == robotxpr || pred == robotypr ) {
				// either robot x or y coordinate

				// refer -> if not exists, create empty ones
				LocMap &roboLoc = tlm.robots[step];
				if( pred == robotxpr ) {
					ID& roboX = roboLoc[entity].first;
					if( roboX != ID_FAIL )
						// duplicate assignment -> abort
						return false;
					else
						roboX = coordinate;
				}
				else {
					ID& roboY = roboLoc[entity].second;
					if( roboY != ID_FAIL )
						// duplicate assignment -> abort
						return false;
					else
						roboY = coordinate;
				}
				relevantIDs.insert(id);
			}
			else if( pred == objxpr || pred == objypr ) {
				// either object x or y coordinate

				// refer -> if not exists, create empty ones
				LocMap &objLoc = tlm.objects[step];
				if( pred == objxpr ) {
					ID& objX = objLoc[entity].first;
					if( objX != ID_FAIL )
						// duplicate assignment -> abort
						return false;
					else
						objX = coordinate;
				}
				else {
					ID& objY = objLoc[entity].second;
					if( objY != ID_FAIL )
						// duplicate assignment -> abort
						return false;
					else
						objY = coordinate;
				}
				relevantIDs.insert(id);
			}
		}
		en++;
	}
	return true;
}

bool extractTimeLocOneObj(TimeLocMap& tlm, IDSet& relevantIDs, RegistryPtr reg, InterpretationConstPtr pi,
		const ID robotxpr, const ID robotypr, const ID objxpr, const ID objypr)
{
	// find relevant input
	bm::bvector<>::enumerator en = pi->getStorage().first();
	bm::bvector<>::enumerator en_end = pi->getStorage().end();
	while (en < en_end)
	{
		// id of current true bit
		ID id(ID::MAINKIND_ATOM | ID::SUBKIND_ATOM_ORDINARYG, *en);
		const OrdinaryAtom& atom = reg->ogatoms.getByID(id);
		if( atom.tuple.size() == 2 )
		{
			// {objectX,objectY}(Coordinate)
			ID pred = atom.tuple[0];
			ID entity;
			ID coordinate = atom.tuple[1];
			LOG(INFO,"got tuple " << printToString<RawPrinter>(id,reg));

			// refer -> if not exists, create empty ones
			LocMap &objLoc = tlm.dobjects;
			if( pred == objxpr || pred == objypr ) {
				// either robot x or y coordinate
				if( pred == objxpr ) {
					ID& objX = objLoc[entity].first;
					if( objX != ID_FAIL )
						// duplicate assignment -> abort
						return false;
					else
						objX = coordinate;
				}
				else {
					ID& objY = objLoc[entity].second;
					if( objY != ID_FAIL )
						// duplicate assignment -> abort
						return false;
					else
						objY = coordinate;
				}
				relevantIDs.insert(id);
			}
		}
		else if( atom.tuple.size() == 4 )
		{
			// {robotX,robotY,objectX,objectY}(Robot,Coordinate,Step)
			ID pred = atom.tuple[0];
			ID entity = atom.tuple[1];
			ID coordinate = atom.tuple[2];
			ID step = atom.tuple[3];
			LOG(INFO,"got tuple " << printToString<RawPrinter>(id,reg));

			if( pred == robotxpr || pred == robotypr ) {
				// either robot x or y coordinate

				// refer -> if not exists, create empty ones
				LocMap &roboLoc = tlm.robots[step];
				if( pred == robotxpr ) {
					ID& roboX = roboLoc[entity].first;
					if( roboX != ID_FAIL )
						// duplicate assignment -> abort
						return false;
					else
						roboX = coordinate;
				}
				else {
					ID& roboY = roboLoc[entity].second;
					if( roboY != ID_FAIL )
						// duplicate assignment -> abort
						return false;
					else
						roboY = coordinate;
				}
				relevantIDs.insert(id);
			}
			else if( pred == objxpr || pred == objypr ) {
				// either object x or y coordinate

				// refer -> if not exists, create empty ones
				LocMap &objLoc = tlm.objects[step];
				if( pred == objxpr ) {
					ID& objX = objLoc[entity].first;
					if( objX != ID_FAIL )
						// duplicate assignment -> abort
						return false;
					else
						objX = coordinate;
				}
				else {
					ID& objY = objLoc[entity].second;
					if( objY != ID_FAIL )
						// duplicate assignment -> abort
						return false;
					else
						objY = coordinate;
				}
				relevantIDs.insert(id);
			}
		}
		en++;
	}
	return true;
}

// return false if any coordinate is only partially specified (i.e., ID_FAIL for one component)
bool checkTimeLocMap(const TimeLocMap& tlm) {
	// collect maps to check
	std::vector<const LocMap*> lms;
	{
		// objects
		lms.push_back(&(tlm.dobjects));
		for(std::map<ID, LocMap>::const_iterator itt = tlm.objects.begin(); itt != tlm.objects.end(); ++itt) {
			lms.push_back(&(itt->second));
		}

		// robots
		for(std::map<ID, LocMap>::const_iterator itt = tlm.robots.begin(); itt != tlm.robots.end(); ++itt) {
			lms.push_back(&(itt->second));
		}
	}

	// check
	BOOST_FOREACH(const LocMap* lmp, lms) {
		const LocMap& lm = *lmp;
		LocMap::const_iterator itl;
		// check each entity
		for(itl = lm.begin(); itl != lm.end(); ++itl) {
			if( itl->second.first == ID_FAIL || itl->second.second == ID_FAIL )
				return false;
		}
	}
	return true;
}

class SenseObjectAtom: public PluginAtom, public SensorRangeCheck
{
public:
	SenseObjectAtom():
		PluginAtom("senseObject", false)
	{
		// robotX(Robot,X,Step)
		addInputPredicate();
		// robotY(Robot,Y,Step)
		addInputPredicate();
		// objectX(Object,X)
		addInputPredicate();
		// objectY(Object,Y)
		addInputPredicate();
		// RangeString
		addInputConstant();
		// spoil (just be true if this is true)
		addInputPredicate();
		// object (all objects we must spoil for)
		addInputPredicate();

		// true for all objects found in range
		setOutputArity(1);
	}

	void collectFoundObjects(IDSet& foundObjects, const TimeLocMap& tlm, float range)
	{
		const LocMap& olm = tlm.dobjects;
		
		for(std::map<ID, LocMap>::const_iterator itt = tlm.robots.begin(); itt != tlm.robots.end(); ++itt)
		{
			LOG(DBG,"collecting found objects for time step " << itt->first.address);
			const LocMap& rlm = itt->second;
			// for all robots
			for(LocMap::const_iterator rit = rlm.begin(); rit != rlm.end(); ++rit)
			{
				LOG(DBG,"  checking robot " << rit->first);
				// for all objects
				for(LocMap::const_iterator oit = olm.begin(); oit != olm.end(); ++oit)
				{
					LOG(DBG,"  checking object " << oit->first);

					ID robot = rit->first;
					unsigned rx = rit->second.first.address;
					unsigned ry = rit->second.second.address;
					ID object = oit->first;
					unsigned ox = oit->second.first.address;
					unsigned oy = oit->second.second.address;
					if( canSee(range, rx, ry, ox, oy) )
						foundObjects.insert(object);
				}
			}

		}
	}

	virtual void retrieve(const Query& query, Answer& answer) throw (PluginError)
	{
		DLVHEX_BENCHMARK_REGISTER_AND_SCOPE(sid,"senseObject");

		RegistryPtr reg = getRegistry();

		InterpretationConstPtr pi = query.interpretation;

		LOG(INFO,"senseObject! " << *pi);

		const ID robotxpr = query.input[0];
		const ID robotypr = query.input[1];
		const ID objxpr = query.input[2];
		const ID objypr = query.input[3];
		const ID sensorrange = query.input[4];
		const ID spoilterm = query.input[5];
		const ID object = query.input[6];

		OrdinaryAtom spoilatom(ID::MAINKIND_ATOM | ID::SUBKIND_ATOM_ORDINARYG);
		spoilatom.tuple.push_back(spoilterm);
		const ID spoilpred = reg->storeOrdinaryGAtom(spoilatom);
		if( pi->getFact(spoilpred.address) ) {
			// spoiled -> true for all objects
			IDSet objects;
			extractObjectTerms(objects, object, reg, pi);
			BOOST_FOREACH(ID obj, objects) {
				Tuple out;
				out.push_back(obj);
				answer.get().push_back(out);
			}
			LOG(INFO,"spoil active -> return true for " << printManyToString<RawPrinter>(Tuple(objects.begin(), objects.end()),",",reg));
			return;
		}

		IDSet relevantIDs;

		TimeLocMap tlm;
		bool aborted = true;
		do {
			// partial
			if( !extractTimeLoc(tlm, relevantIDs, reg, pi, robotxpr, robotypr, objxpr, objypr) ) {
				LOG(INFO,"extractTimeLoc aborted");
				break;
			}

			// partial
			if( !checkTimeLocMap(tlm) ) {
				LOG(INFO,"checkTimeLocMap aborted");
				break;
			}

			const std::string& sensor = reg->getTermStringByID(sensorrange);
			float range;
			{
				std::stringstream ss;
				if( sensor[0] == '"' )
					ss << sensor.substr(1,sensor.size()-2);
				else
					ss << sensor;
				ss >> range;
			}
			LOG(INFO,"checking with sensor range " << range);

			IDSet foundObjects;
			collectFoundObjects(foundObjects, tlm, range);

			aborted = false;
			BOOST_FOREACH(ID obj, foundObjects) {
				Tuple out;
				out.push_back(obj);
				answer.get().push_back(out);
			}
		}
		while(false);
		answer.use();
	}

	/*
	throw PluginError("method should not be called, we use extlearning!");
	virtual void
	retrieve(const Query& query, Answer& answer, NogoodContainerPtr nogoods) throw (PluginError)
	{
	}
	*/
};

class SenseOneObjectAtom: public PluginAtom, public SensorRangeCheck
{
public:
	SenseOneObjectAtom():
		PluginAtom("senseOneObject", false)
	{
		// robotX(Robot,X,Step)
		addInputPredicate();
		// robotY(Robot,Y,Step)
		addInputPredicate();
		// objectX(X)
		addInputPredicate();
		// objectY(Y)
		addInputPredicate();
		// RangeString
		addInputConstant();
		// spoil (just be true if this is true)
		addInputPredicate();

		// true for all objects found in range
		setOutputArity(0);
	}

	void collectFoundObjects(IDSet& foundObjects, const TimeLocMap& tlm, float range)
	{
		const LocMap& olm = tlm.dobjects;
		
		for(std::map<ID, LocMap>::const_iterator itt = tlm.robots.begin(); itt != tlm.robots.end(); ++itt)
		{
			LOG(DBG,"collecting found objects for time step " << itt->first.address);
			const LocMap& rlm = itt->second;
			// for all robots
			for(LocMap::const_iterator rit = rlm.begin(); rit != rlm.end(); ++rit)
			{
				LOG(DBG,"  checking robot " << rit->first);
				// for all objects
				for(LocMap::const_iterator oit = olm.begin(); oit != olm.end(); ++oit)
				{
					LOG(DBG,"  checking object " << oit->first);

					ID robot = rit->first;
					unsigned rx = rit->second.first.address;
					unsigned ry = rit->second.second.address;
					ID object = oit->first;
					unsigned ox = oit->second.first.address;
					unsigned oy = oit->second.second.address;
					if( canSee(range, rx, ry, ox, oy) )
						foundObjects.insert(object);
				}
			}

		}
	}

	virtual void retrieve(const Query& query, Answer& answer) throw (PluginError)
	{
		DLVHEX_BENCHMARK_REGISTER_AND_SCOPE(sid,"senseOneObject");

		RegistryPtr reg = getRegistry();

		InterpretationConstPtr pi = query.interpretation;

		LOG(INFO,"senseOneObject! " << *pi);

		const ID robotxpr = query.input[0];
		const ID robotypr = query.input[1];
		const ID objxpr = query.input[2];
		const ID objypr = query.input[3];
		const ID sensorrange = query.input[4];
		const ID spoilterm = query.input[5];

		OrdinaryAtom spoilatom(ID::MAINKIND_ATOM | ID::SUBKIND_ATOM_ORDINARYG);
		spoilatom.tuple.push_back(spoilterm);
		const ID spoilpred = reg->storeOrdinaryGAtom(spoilatom);
		if( pi->getFact(spoilpred.address) ) {
			// spoiled -> true for all objects
			answer.get().push_back(Tuple());
			LOG(INFO,"spoil active -> return true");
			return;
		}

		IDSet relevantIDs;

		TimeLocMap tlm;
		bool aborted = true;
		do {
			// partial
			if( !extractTimeLocOneObj(tlm, relevantIDs, reg, pi, robotxpr, robotypr, objxpr, objypr) ) {
				LOG(INFO,"extractTimeLoc aborted");
				break;
			}

			// partial
			if( !checkTimeLocMap(tlm) ) {
				LOG(INFO,"checkTimeLocMap aborted");
				break;
			}

			const std::string& sensor = reg->getTermStringByID(sensorrange);
			float range;
			{
				std::stringstream ss;
				if( sensor[0] == '"' )
					ss << sensor.substr(1,sensor.size()-2);
				else
					ss << sensor;
				ss >> range;
			}
			LOG(INFO,"checking with sensor range " << range);

			IDSet foundObjects;
			collectFoundObjects(foundObjects, tlm, range);

			aborted = false;
			if( !foundObjects.empty() )
				answer.get().push_back(Tuple());
		}
		while(false);
		answer.use();
	}

	/*
	throw PluginError("method should not be called, we use extlearning!");
	virtual void
	retrieve(const Query& query, Answer& answer, NogoodContainerPtr nogoods) throw (PluginError)
	{
	}
	*/
};

class SenseObjectVLAtom: public PluginAtom, public SensorRangeCheck
{
public:
	SenseObjectVLAtom():
		PluginAtom("senseObjectVL", false)
	{
		// robotX(Robot,X,Step)
		addInputPredicate();
		// robotY(Robot,Y,Step)
		addInputPredicate();
		// objectX(Object,Y,Step)
		addInputPredicate();
		// objectY(Object,Y,Step)
		addInputPredicate();
		// RangeString
		addInputConstant();
		// spoil (just be true if this is true)
		addInputPredicate();
		// object (all objects we must spoil for)
		addInputPredicate();

		// true for all objects found in range
		setOutputArity(1);
	}

	void collectFoundObjects(IDSet& foundObjects, const TimeLocMap& tlm, float range)
	{
		typedef std::map<ID, LocMap>::const_iterator TLMIterator;
		for(TLMIterator itt = tlm.robots.begin(); itt != tlm.robots.end(); ++itt)
		{
			LOG(DBG,"collecting found objects for time step " << itt->first.address);
			const LocMap& rlm = itt->second;
			// for all robots
			for(LocMap::const_iterator rit = rlm.begin(); rit != rlm.end(); ++rit)
			{
				LOG(DBG,"  checking robot " << rit->first);
				// for all objects in that time step
				TLMIterator oit = tlm.objects.find(itt->first);
				if( oit != tlm.objects.end() )
				{
					// if there are objects at that time
					const LocMap& olm = oit->second;
					for(LocMap::const_iterator oit = olm.begin(); oit != olm.end(); ++oit)
					{
						LOG(DBG,"  checking object " << oit->first);

						ID robot = rit->first;
						unsigned rx = rit->second.first.address;
						unsigned ry = rit->second.second.address;
						ID object = oit->first;
						unsigned ox = oit->second.first.address;
						unsigned oy = oit->second.second.address;
						if( canSee(range, rx, ry, ox, oy) )
							foundObjects.insert(object);
					}
				}
			}

		}
	}

	virtual void retrieve(const Query& query, Answer& answer) throw (PluginError)
	{
		DLVHEX_BENCHMARK_REGISTER_AND_SCOPE(sid,"senseObject");

		RegistryPtr reg = getRegistry();

		InterpretationConstPtr pi = query.interpretation;

		LOG(INFO,"senseObject! " << *pi);

		const ID robotxpr = query.input[0];
		const ID robotypr = query.input[1];
		const ID objxpr = query.input[2];
		const ID objypr = query.input[3];
		const ID sensorrange = query.input[4];
		const ID spoilterm = query.input[5];
		const ID object = query.input[6];

		OrdinaryAtom spoilatom(ID::MAINKIND_ATOM | ID::SUBKIND_ATOM_ORDINARYG);
		spoilatom.tuple.push_back(spoilterm);
		const ID spoilpred = reg->storeOrdinaryGAtom(spoilatom);
		if( pi->getFact(spoilpred.address) ) {
			// spoiled -> true for all objects
			IDSet objects;
			extractObjectTerms(objects, object, reg, pi);
			BOOST_FOREACH(ID obj, objects) {
				Tuple out;
				out.push_back(obj);
				answer.get().push_back(out);
			}
			LOG(INFO,"spoil active -> return true for " << printManyToString<RawPrinter>(Tuple(objects.begin(), objects.end()),",",reg));
			return;
		}

		IDSet relevantIDs;

		TimeLocMap tlm;
		bool aborted = true;
		do {
			// partial
			if( !extractTimeLoc(tlm, relevantIDs, reg, pi, robotxpr, robotypr, objxpr, objypr) ) {
				LOG(INFO,"extractTimeLoc aborted");
				break;
			}

			// partial
			if( !checkTimeLocMap(tlm) ) {
				LOG(INFO,"checkTimeLocMap aborted");
				break;
			}

			const std::string& sensor = reg->getTermStringByID(sensorrange);
			float range;
			{
				std::stringstream ss;
				if( sensor[0] == '"' )
					ss << sensor.substr(1,sensor.size()-2);
				else
					ss << sensor;
				ss >> range;
			}
			LOG(INFO,"checking with sensor range " << range);

			IDSet foundObjects;
			collectFoundObjects(foundObjects, tlm, range);

			aborted = false;
			BOOST_FOREACH(ID obj, foundObjects) {
				Tuple out;
				out.push_back(obj);
				answer.get().push_back(out);
			}
		}
		while(false);
		answer.use();
	}

	/*
	throw PluginError("method should not be called, we use extlearning!");
	virtual void
	retrieve(const Query& query, Answer& answer, NogoodContainerPtr nogoods) throw (PluginError)
	{
	}
	*/
};

//
// A plugin must derive from PluginInterface
//
class SensorsPlugin : public PluginInterface
{
	public:
		SensorsPlugin() 
		{
			setNameVersion(PACKAGE_TARNAME,LEGGEDLOCOMOTIONPLUGIN_VERSION_MAJOR,LEGGEDLOCOMOTIONPLUGIN_VERSION_MINOR,LEGGEDLOCOMOTIONPLUGIN_VERSION_MICRO);
		}

		virtual std::vector<PluginAtomPtr> createAtoms(ProgramCtx& ctx) const
		{
			std::vector<PluginAtomPtr> ret;

			ctx.benchmarksToSnapshotAtFirstModel.insert(std::make_pair("senseObject", "senseObject calls to first model"));

			// return smart pointer with deleter (i.e., delete code compiled into this plugin)
			ret.push_back(PluginAtomPtr(new SenseObjectAtom, PluginPtrDeleter<PluginAtom>()));
			ret.push_back(PluginAtomPtr(new SenseOneObjectAtom, PluginPtrDeleter<PluginAtom>()));
			ret.push_back(PluginAtomPtr(new SenseObjectVLAtom, PluginPtrDeleter<PluginAtom>()));

			return ret;
		}

		virtual void processOptions(std::list<const char*>& pluginOptions, ProgramCtx& ctx)
		{
		}
};

//
// now instantiate the plugin
//
SensorsPlugin thePlugin;

} // namespace sensors

//
// let it be loaded by dlvhex!
//

IMPLEMENT_PLUGINABIVERSIONFUNCTION

// return plain C type s.t. all compilers and linkers will like this code
extern "C"
void * PLUGINIMPORTFUNCTION()
{
	return reinterpret_cast<void*>(&sensors::thePlugin);
}

// vim:sw=8:ts=8:softtabstop=8:noet:
