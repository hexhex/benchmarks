
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

	enum Rewritingmode { DISABLED, SAT, UNSAT };
	Rewritingmode mode;

	SatUnsatPluginCtxData():
		mode(DISABLED) {}
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

// base DIMACS parsing functionality
class InputConverterBase:
	public PluginConverter
{
public:
  InputConverterBase(PluginCtxData& pcd):
		pcd(pcd) {}
  virtual ~InputConverterBase() {}

  virtual void convert(std::istream& i, std::ostream& o);

protected:
	virtual void rewriteVariable(std::ostream& out, unsigned posidx) = 0;
	virtual void rewriteClause(std::ostream& out, const std::vector<int>& variables) = 0;
	virtual void rewriteAdditional(std::ostream& out) = 0;

protected:
  PluginCtxData& pcd;

	unsigned numvars;
	unsigned numclauses;
	std::set<unsigned> variables;
	std::list<std::vector<int> > clauses;
};

void InputConverterBase::convert(std::istream& i, std::ostream& o)
{
	// parse dimacs from i into variables and clauses
	DBGLOG(DBG,"parsing dimacs");

	std::string line;

	numvars = 0;
	numclauses = 0;

	char c;
	do
	{
		i >> c;
		if( c == 'c' )
		{
			std::getline(i, line);
			DBGLOG(DBG,"skipping comment input line '" << line << "'");
			continue;
		}
		else if( c == 'p' )
		{
			std::string str;
			i >> str;
			if( str != "cnf" )
				throw std::runtime_error("can only process 'cnf' dimacs!");
			i >> numvars >> numclauses;
			LOG(INFO,"got 'p cnf' with " << numvars << " variables and " << numclauses << " clauses");
		}
		else
			throw std::runtime_error("malformed dimacs input line at beginning!");
	}
	while(i.good() && numvars == 0 && numclauses == 0);

	if( !i.good() )
		throw std::runtime_error("malformed dimacs input! (found no 'p' line)");
	
	variables.clear();
	clauses.clear();
	unsigned atclause = 1;
	do
	{
		std::vector<int> clause;
		int var;
		do
		{
			i >> var;
			if( var != 0 )
			{
				clause.push_back(var);
				if( var < 0 )
					variables.insert(-var);
				else
					variables.insert(var);
			}
			else
				break;
		}
		while(i.good());
		
		if( i.good() )
		{
			clauses.push_back(clause);
			atclause++;
		}
	}
	while(i.good() && atclause <= numclauses);

	DBGLOG(DBG,"read " << atclause << " clauses");

	// do some minimal verification
	if( variables.size() != numvars )
	{
		LOG(ERROR,"got " << variables.size() << " variables but input said there are " << numvars);
		throw std::runtime_error("malformed DIMACS input");
	}
	if( clauses.size() != numclauses )
	{
		LOG(ERROR,"got " << clauses.size() << " clauses but input said there are " << numclauses);
		throw std::runtime_error("malformed DIMACS input");
	}

	// rewrite
	for(auto it = variables.begin(); it != variables.end(); ++it)
	{
		rewriteVariable(o, *it);
	}
	for(auto it = clauses.begin(); it != clauses.end(); ++it)
	{
		rewriteClause(o, *it);
	}
	rewriteAdditional(o);
}

class InputConverterSAT:
  public InputConverterBase
{
public:
  InputConverterSAT(PluginCtxData& pcd):
		InputConverterBase(pcd) {}

protected:
	inline void writevar(std::ostream& out, int var) // final 
	{
		if( var < 0 )
			out << "nx" << -var;
		else
			out << "x" << var;
	}

	virtual void rewriteVariable(std::ostream& out, unsigned posidx)
	{
		int idx = posidx;
		writevar(out, idx);
		out << " v ";
		writevar(out, -idx);
		out << ".\n";
	}

	virtual void rewriteClause(std::ostream& out, const std::vector<int>& variables)
	{
		out << ":- ";
		auto it = variables.begin();
		writevar(out, *it);
		for(;it != variables.end(); ++it)
		{
			out << ", ";
			writevar(out, *it);
		}
		out << ".\n";
	}

	virtual void rewriteAdditional(std::ostream& out)
	{
	}
};

class InputConverterUNSAT:
  public InputConverterBase
{
public:
  InputConverterUNSAT(PluginCtxData& pcd):
		InputConverterBase(pcd) {}

protected:
	inline void writevar(std::ostream& out, int var) // final 
	{
		if( var < 0 )
			out << "x" << -var << "(m)";
		else
			out << "x" << var << "(p)";
	}

	virtual void rewriteVariable(std::ostream& out, unsigned posidx)
	{
		std::string vp, vz, vm;
		{
			std::stringstream ss;
			ss << "x" << posidx;
			vp = ss.str() + "(p)";
			vz = ss.str() + "(z)";
			vm = ss.str() + "(m)";
		}
		out << vz << ".\n";
		out << vp << " :- &avg[x" << posidx << "](z).\n";
		out << vm << " :- &avg[x" << posidx << "](z).\n";
		out << vp << " :- w.\n";
		out << vm << " :- w.\n";
	}

	virtual void rewriteClause(std::ostream& out, const std::vector<int>& variables)
	{
		out << "w :- ";
		auto it = variables.begin();
		writevar(out, *it);
		for(;it != variables.end(); ++it)
		{
			out << ", ";
			writevar(out, *it);
		}
		out << ".\n";
	}

	virtual void rewriteAdditional(std::ostream& out)
	{
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
	
	// output help message for this plugin
	virtual void
	printUsage(std::ostream& o) const
	{
		//    123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-
		o << "     --satunsatmode=<mode>     Enable input rewriting (from DIMACS to <mode>):\n"
			   "                                sat   trivial satisfiability encoding\n"
				 "                                unsat unsatisfiability saturation encoding" << std::endl;
	}

	virtual void 
	processOptions(std::list<const char*>& pluginOptions, ProgramCtx& ctx)
	{
		PluginCtxData& pcd = ctx.getPluginData<SatUnsatPlugin>();

		// prepare registry: add terms we need
		pcd.idp = ctx.registry()->storeConstantTerm("p");
		pcd.idz = ctx.registry()->storeConstantTerm("z");
		pcd.idm = ctx.registry()->storeConstantTerm("m");

		// look which mode, if any
		typedef std::list<const char*>::iterator Iterator;
		Iterator it;
		it = pluginOptions.begin();
		while( it != pluginOptions.end() )
		{
			bool processed = false;
			const std::string str(*it);
			if( str == "--satunsatmode=sat" )
			{
				pcd.mode = SatUnsatPluginCtxData::SAT;
				processed = true;
			}
			else if( str == "--satunsatmode=unsat" )
			{
				pcd.mode = SatUnsatPluginCtxData::UNSAT;
				processed = true;
			}

			if( processed )
			{
				// return value of erase: element after it, maybe end()
				DBGLOG(DBG,"SatUnsatPlugin successfully processed option " << str);
				it = pluginOptions.erase(it);
			}
			else
			{
				it++;
			}
		}
	}

	PluginConverterPtr
	createConverter(ProgramCtx& ctx)
	{
		PluginCtxData& pcd = ctx.getPluginData<SatUnsatPlugin>();
		switch(pcd.mode)
		{
		case PluginCtxData::SAT:
			return PluginConverterPtr(new InputConverterSAT(pcd));
		case PluginCtxData::UNSAT:
			return PluginConverterPtr(new InputConverterUNSAT(pcd));
		}
		return PluginConverterPtr();
	}
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


