
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
#include <fstream>
#include <cstdio>


namespace dlvhex {
namespace benchmark {


struct StrategicPluginCtxData:
	public dlvhex::PluginData
{
	struct StrategicFile{
		std::set<ID> companies, products;
		std::map<ID, std::set<std::set<ID> > > controlledBy;
		std::map<ID, std::set<ID> > producedBy;
	};

	std::map<ID, StrategicFile> fileCache;

	StrategicPluginCtxData() {}

	void load(RegistryPtr reg, ID filename){

		DBGLOG(DBG, "Loading strategiy file \"" << filename << "\"");
		if (fileCache.find(filename) == fileCache.end()){
			// load file
			std::ifstream file(reg->terms.getByID(filename).getUnquotedString().c_str());
			if (file.is_open()){
				StrategicFile instance;
				std::string type;
				while(!file.eof()){
					file >> type;
					if (file.eof()) break;

					if (type == "controlled_by"){
						std::string controlledOne, controller1, controller2, controller3, controller4;
						file >> controlledOne;
						file >> controller1;
						file >> controller2;
						file >> controller3;
						file >> controller4;

						Term controlledOneT(ID::MAINKIND_TERM | ID::SUBKIND_TERM_CONSTANT, controlledOne);
						Term controller1T(ID::MAINKIND_TERM | ID::SUBKIND_TERM_CONSTANT, controller1);
						Term controller2T(ID::MAINKIND_TERM | ID::SUBKIND_TERM_CONSTANT, controller2);
						Term controller3T(ID::MAINKIND_TERM | ID::SUBKIND_TERM_CONSTANT, controller3);
						Term controller4T(ID::MAINKIND_TERM | ID::SUBKIND_TERM_CONSTANT, controller4);

						std::set<ID> controller;
						controller.insert(reg->storeTerm(controller1T));
						controller.insert(reg->storeTerm(controller2T));
						controller.insert(reg->storeTerm(controller3T));
						controller.insert(reg->storeTerm(controller4T));

						instance.controlledBy[reg->storeTerm(controlledOneT)].insert(controller);

						instance.companies.insert(reg->storeTerm(controlledOneT));
						instance.companies.insert(reg->storeTerm(controller1T));
						instance.companies.insert(reg->storeTerm(controller2T));
						instance.companies.insert(reg->storeTerm(controller3T));
						instance.companies.insert(reg->storeTerm(controller4T));
					}

					if (type == "produced_by"){
						std::string product, producer1, producer2, producer3, producer4;
						file >> product;
						file >> producer1;
						file >> producer2;
						file >> producer3;
						file >> producer4;

						Term productT(ID::MAINKIND_TERM | ID::SUBKIND_TERM_CONSTANT, product);
						Term producer1T(ID::MAINKIND_TERM | ID::SUBKIND_TERM_CONSTANT, producer1);
						Term producer2T(ID::MAINKIND_TERM | ID::SUBKIND_TERM_CONSTANT, producer2);
						Term producer3T(ID::MAINKIND_TERM | ID::SUBKIND_TERM_CONSTANT, producer3);
						Term producer4T(ID::MAINKIND_TERM | ID::SUBKIND_TERM_CONSTANT, producer4);

						std::set<ID> producers;
						producers.insert(reg->storeTerm(producer1T));
						producers.insert(reg->storeTerm(producer2T));
						producers.insert(reg->storeTerm(producer3T));
						producers.insert(reg->storeTerm(producer4T));

						instance.producedBy[reg->storeTerm(productT)] = producers;

						instance.products.insert(reg->storeTerm(productT));
						instance.companies.insert(reg->storeTerm(producer1T));
						instance.companies.insert(reg->storeTerm(producer2T));
						instance.companies.insert(reg->storeTerm(producer3T));
						instance.companies.insert(reg->storeTerm(producer4T));

					}
					std::string line;
					std::getline(file, line);
				}
				file.close();
				fileCache[filename] = instance;
				DBGLOG(DBG, "Loaded strategiy file \"" << filename << "\"");
			}
		}
	}

	StrategicFile& operator[](ID filename){

		assert (fileCache.find(filename) != fileCache.end());
		return fileCache[filename];
	}
};

typedef StrategicPluginCtxData PluginCtxData;

class CompanyAtom : public PluginAtom
{
public:
	PluginCtxData& pcd;

public:
	CompanyAtom(PluginCtxData& pcd):
		PluginAtom("company", false),
		pcd(pcd)
	{
		addInputConstant();
		setOutputArity(1);
	}

	virtual void
	retrieve(const Query& query, Answer& answer) throw (PluginError)
	{
		assert(query.input.size() == 1);

		RegistryPtr reg = getRegistry();

		pcd.load(reg, query.input[0]);

		BOOST_FOREACH (ID company, pcd[query.input[0]].companies){
			Tuple out;
			out.push_back(company);
			answer.get().push_back(out); 
		}
	}
};

class ProductAtom : public PluginAtom
{
public:
	PluginCtxData& pcd;

public:
	ProductAtom(PluginCtxData& pcd):
		PluginAtom("product", false),
		pcd(pcd)
	{
		addInputConstant();
		setOutputArity(1);
	}

	virtual void
	retrieve(const Query& query, Answer& answer) throw (PluginError)
	{
		assert(query.input.size() == 1);

		RegistryPtr reg = getRegistry();

		pcd.load(reg, query.input[0]);

		BOOST_FOREACH (ID product, pcd[query.input[0]].products){
			Tuple out;
			out.push_back(product);
			answer.get().push_back(out); 
		}
	}
};

class ControlledByAtom : public PluginAtom
{
public:
	PluginCtxData& pcd;

public:
	ControlledByAtom(PluginCtxData& pcd):
		PluginAtom("controlledBy", false),
		pcd(pcd)
	{
		addInputConstant();
		addInputConstant();
		setOutputArity(4);
	}

	virtual void
	retrieve(const Query& query, Answer& answer) throw (PluginError)
	{
		assert(query.input.size() == 2);

		RegistryPtr reg = getRegistry();

		pcd.load(reg, query.input[0]);
		typedef std::set<ID> ControllerGroup;
		BOOST_FOREACH (ControllerGroup controllerGroup, pcd[query.input[0]].controlledBy[query.input[1]]){
			Tuple out;
			BOOST_FOREACH (ID controller, controllerGroup){
				out.push_back(controller);
			}
			for (int i = out.size(); i < 4; ++i){
				out.push_back(*controllerGroup.begin());
			}
			answer.get().push_back(out); 
		}
	}
};

class ProducesAtom : public PluginAtom
{
public:
	PluginCtxData& pcd;

public:
	ProducesAtom(PluginCtxData& pcd):
		PluginAtom("producedBy", false),
		pcd(pcd)
	{
		addInputConstant();
		addInputConstant();
		setOutputArity(4);
	}

	virtual void
	retrieve(const Query& query, Answer& answer) throw (PluginError)
	{
		assert(query.input.size() == 2);

		RegistryPtr reg = getRegistry();

		pcd.load(reg, query.input[0]);
		Tuple out;
		BOOST_FOREACH (ID producer, pcd[query.input[0]].producedBy[query.input[1]]){
			out.push_back(producer);
		}
		for (int i = out.size(); i < 4; ++i){
			out.push_back(*pcd[query.input[0]].producedBy[query.input[1]].begin());
		}
		answer.get().push_back(out); 
	}
};
/*
class StrategicRewriter : public PluginRewriter{

	void rewrite(ProgramCtx& ctx){

		// create controlledBy and producedBy predicate
		Term controlledByTerm(ID::MAINKIND_TERM | ID::SUBKIND_TERM_CONSTANT, "controlled_by");
		ID controlledBy = ctx.registry()->storeTerm(controlledByTerm);
		Term producedByTerm(ID::MAINKIND_TERM | ID::SUBKIND_TERM_CONSTANT, "produced_by");
		ID producedBy = ctx.registry()->storeTerm(producedByTerm);

		StrategicPluginCtxData::StrategicFile instance;

		// for all atoms in the edb
		bm::bvector<>::enumerator en = ctx.edb->getStorage().first();
		bm::bvector<>::enumerator en_end = ctx.edb->getStorage().end();
		while (en < en_end){
			const OrdinaryAtom& ogatom = ctx.registry()->ogatoms.getByAddress(*en);
			if (ogatom.tuple[0] == controlledBy){
				instance.companies.insert(ogatom.tuple[1]);
				for (int i = 2; i < ogatom.tuple.size(); ++i){
					instance.controlledBy[ogatom.tuple[1]].insert(ogatom.tuple[i]);
				}
			}
			if (ogatom.tuple[0] == producedBy){
				instance.goods.insert(ogatom.tuple[1]);
				for (int i = 2; i < ogatom.tuple.size(); ++i){
					instance.produces[ogatom.tuple[1]].insert(ogatom.tuple[i]);
				}
			}

			en++;
		}

		// construct query program
		ctx.edb->clear();

		// determine maximum number of controllers and producers
		typedef std::pair<ID, std::set<ID> > Pair;
		numControllers = 0;
		BOOST_FOREACH (Pair p, instance.controlledBy){
			numControllers = p.second.size() > numControllers ? p.second.size() : numControllers;
		}
		numProducers = 0;
		BOOST_FOREACH (Pair p, instance.producedBy){
			numProducers = p.second.size() > numControllers ? p.second.size() : numControllers;
		}

		// construct
		//	strategic(X1) | strategic(X2) | strategic(X3) | strategic(X4) :- produced_by(X,X1,X2,X3,X4).
		//	strategic(W) :- controlled_by(W,X1,X2,X3,X4), strategic(X1), strategic(X2), strategic(X3), strategic(X4).
		Rule selection(ID::MAINKIND_RULE | ID::PROPERTY_RULE_DISJ);
		for (int i = 0; i < numProducers; ++i){
			OrdinaryAtom h(ID::MAINKIND_ATOM | ID::SUBKIND_ATOM_ORDINARYN);

		}
	}
};
*/

/*
class InputConverter:
	public PluginConverter
{
public:
  InputConverter(PluginCtxData& pcd):
		pcd(pcd) {}
  virtual ~InputConverterBase() {}

  virtual void convert(std::istream& i, std::ostream& o);

protected:
  PluginCtxData& pcd;

	unsigned numControllers;
	unsigned numProducers;
};

void InputConverterBase::convert(std::istream& i, std::ostream& o)
{
	// determine maximum number of controllers and producers
	typedef std::pair<ID, std::set<ID> > Pair;
	numControllers = 0;
	BOOST_FOREACH (Pair p, pcd.controlledBy){
		numControllers = p.second.size() > numControllers ? p.second.size() : numControllers;
	}
	numProducers = 0;
	BOOST_FOREACH (Pair p, pcd.producedBy){
		numProducers = p.second.size() > numControllers ? p.second.size() : numControllers;
	}

	while (!i.eof()){
		// read type
		std::string type;
		i >> type;
	}

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
*/

class StrategicPlugin : public PluginInterface
{
public:
	typedef StrategicPluginCtxData CtxData;

public:
	StrategicPlugin() 
	{
		setNameVersion(PACKAGE_TARNAME,
				STRATEGICPLUGIN_VERSION_MAJOR,STRATEGICPLUGIN_VERSION_MINOR,STRATEGICPLUGIN_VERSION_MICRO);
	}

	virtual std::vector<PluginAtomPtr> createAtoms(ProgramCtx& ctx) const
	{
		std::vector<PluginAtomPtr> ret;
	
		// return smart pointer with deleter (i.e., delete code compiled into this plugin)
		ret.push_back(PluginAtomPtr(
					new CompanyAtom(ctx.getPluginData<StrategicPlugin>()),
					PluginPtrDeleter<PluginAtom>()));
		ret.push_back(PluginAtomPtr(
					new ProductAtom(ctx.getPluginData<StrategicPlugin>()),
					PluginPtrDeleter<PluginAtom>()));
		ret.push_back(PluginAtomPtr(
					new ControlledByAtom(ctx.getPluginData<StrategicPlugin>()),
					PluginPtrDeleter<PluginAtom>()));
		ret.push_back(PluginAtomPtr(
					new ProducesAtom(ctx.getPluginData<StrategicPlugin>()),
					PluginPtrDeleter<PluginAtom>()));

		return ret;
	}

/*
	// output help message for this plugin
	virtual void
	printUsage(std::ostream& o) const
	{
		//    123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-
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
*/
};

    
//
// now instantiate the plugin
//
StrategicPlugin theStrategicPlugin;

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
	return reinterpret_cast<void*>(& dlvhex::benchmark::theStrategicPlugin);
}


