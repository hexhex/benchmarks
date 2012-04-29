
//
// this include is necessary
//

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif /* HAVE_CONFIG_H */

#include <dlvhex2/PluginInterface.h>
#include <dlvhex2/Term.h>
#include <dlvhex2/Registry.h>
#include <dlvhex2/ProgramCtx.h>

#include <string>
#include <sstream>
#include <cstdio>


namespace dlvhex {
namespace benchmark {

struct SatUnsatPluginCtxData:
	public dlvhex::PluginData
{
	ID idp;
	ID idz;
	ID idm;

	bool enabled;

	SatUnsatPluginCtxData():
		enabled(false) {}
};

typedef SatUnsatPluginCtxData PluginCtxData;

class AvgAtom : public PluginAtom
{
public:
	PluginCtxData& pcd;

public:
	AvgAtom(PluginCtxData& pcd):
		PluginAtom("avg", false),
		pcd(pcd)
	{
		addInputPredicate();
		setOutputArity(1);
	}
	
	// given input predicate x
	// we are true for p if x(p) is in interpretation and x(m) is not in interpretation
	// we are true for m if x(m) is in interpretation and x(p) is not in interpretation
	// we are true for z otherwise
	// (we are the average function where p = +1, m = -1, z = 0
	virtual void
	retrieve(const Query& query, Answer& answer) throw (PluginError)
	{
		assert(query.input.size() == 1);

		RegistryPtr reg = getRegistry();

		// get id for xp
		OrdinaryAtom xp(ID::MAINKIND_ATOM | ID::SUBKIND_ATOM_ORDINARYG);
		xp.tuple.push_back(query.input[0]);
		xp.tuple.push_back(pcd.idp);
		ID idxp = reg->storeOrdinaryGAtom(xp);

		// get id for xm
		OrdinaryAtom xm(ID::MAINKIND_ATOM | ID::SUBKIND_ATOM_ORDINARYG);
		xm.tuple.push_back(query.input[0]);
		xm.tuple.push_back(pcd.idm);
		ID idxm = reg->storeOrdinaryGAtom(xm);

		Tuple out;

		bool hasxp = query.interpretation->getFact(idxp.address);
		bool hasxm = query.interpretation->getFact(idxm.address);
		if( hasxp && !hasxm )
		{
			out.push_back(pcd.idp);
		}
		else if( !hasxp && hasxm )
		{
			out.push_back(pcd.idm);
		}
		else
		{
			out.push_back(pcd.idz);
		}
		answer.get().push_back(out); 
	}
};

class SatUnsatPlugin : public PluginInterface
{
public:
	typedef SatUnsatPluginCtxData CtxData;

public:
	SatUnsatPlugin() 
	{
		setNameVersion(PACKAGE_TARNAME,
				SATUNSATPLUGIN_VERSION_MAJOR,SATUNSATPLUGIN_VERSION_MINOR,SATUNSATPLUGIN_VERSION_MICRO);
	}

	virtual std::vector<PluginAtomPtr> createAtoms(ProgramCtx& ctx) const
	{
		std::vector<PluginAtomPtr> ret;
	
		// return smart pointer with deleter (i.e., delete code compiled into this plugin)
		ret.push_back(PluginAtomPtr(
					new AvgAtom(ctx.getPluginData<SatUnsatPlugin>()),
					PluginPtrDeleter<PluginAtom>()));
	
		return ret;
	}
	
	virtual void 
	processOptions(std::list<const char*>& pluginOptions, ProgramCtx& ctx)
	{
		PluginCtxData& pcd = ctx.getPluginData<SatUnsatPlugin>();

		// prepare registry: add terms we need
		pcd.idp = ctx.registry()->storeConstantTerm("p");
		pcd.idz = ctx.registry()->storeConstantTerm("z");
		pcd.idm = ctx.registry()->storeConstantTerm("m");

		// TODO look if enabled and update pcd accordingly
	
	}

	// TODO input rewriter iff enabled
	
};

    
//
// now instantiate the plugin
//
SatUnsatPlugin theSatUnsatPlugin;

} // namespace benchmark
} // namespace dlvhex

//
// let it be loaded by dlvhex!
//

IMPLEMENT_PLUGINABIVERSIONFUNCTION

// return plain C type s.t. all compilers and linkers will like this code
extern "C"
void * PLUGINIMPORTFUNCTION()
{
	return reinterpret_cast<void*>(& dlvhex::benchmark::theSatUnsatPlugin);
}


