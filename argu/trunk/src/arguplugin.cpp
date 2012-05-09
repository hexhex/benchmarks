
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
#include <dlvhex2/OrdinaryASPProgram.h>
#include <dlvhex2/ASPSolverManager.h>
#include <dlvhex2/ASPSolver.h>
#include <dlvhex2/HexParser.h>
#include <dlvhex2/Printhelpers.h>
#include <dlvhex2/Printer.h>

#include <string>
#include <sstream>
#include <fstream>
#include <cstdio>


namespace dlvhex {
namespace argu {

struct ArguPluginCtxData:
	public dlvhex::PluginData
{
	enum Rewritingmode { DISABLED, IDEAL };
	Rewritingmode mode;

	ArguPluginCtxData():
		mode(DISABLED) {}
};

typedef ArguPluginCtxData PluginCtxData;


// Argh!
class ArgSemExtAtom:
  public PluginAtom
{
public:
  ArgSemExtAtom():
    PluginAtom("argSemExt", 0)
  {
    // semantics \in \{ adm, pref \}
    addInputConstant();
    // arguments/1
    addInputPredicate();
    // attack relation/2
    addInputPredicate();
    // extension candidate/1 \subseteq arguments
    addInputPredicate();
    // pspoil (atom is always true if pspoil is true)
    addInputPredicate();
    // nspoil (atom is always false if nspoil is true)
    addInputPredicate();
    
    // output = truth value
    setOutputArity(0);
  }
  
  virtual void
  retrieve(const Query& query, Answer& answer) throw (PluginError);

protected:
  std::map<ID, PredicateMaskPtr> predMasks;

  PredicateMask& getPredicateMask(ID forID, RegistryPtr reg)
  {
    auto it = predMasks.find(forID);
    if( it == predMasks.end() )
    {
      PredicateMaskPtr pmp(new PredicateMask);
      pmp->setRegistry(reg);
      pmp->addPredicate(forID);
      predMasks.insert(std::make_pair(forID, pmp));
      return *pmp;
    }
    else
    {
      return *it->second;
    }
  }
};

void
ArgSemExtAtom::retrieve(const Query& query, Answer& answer) throw (PluginError)
{
  assert(query.input.size() == 6);

  RegistryPtr reg = getRegistry();

  // check if pspoil is true
  {
    // id of constant of saturate/spoil predicate
    ID saturate_pred = query.input[4];

    // get id of 0-ary atom
    OrdinaryAtom saturate_oatom(ID::MAINKIND_ATOM | ID::SUBKIND_ATOM_ORDINARYG);
    saturate_oatom.tuple.push_back(saturate_pred);
    ID saturate_atom = reg->storeOrdinaryGAtom(saturate_oatom);
    DBGLOG(DBG,"got saturate_pred=" << saturate_pred << " and saturate_atom=" << saturate_atom);

    // check if atom <saturate_pred> is true in interpretation
    bool saturate = query.interpretation->getFact(saturate_atom.address);
    LOG(DBG,"SaturationMetaAtom called with saturate=" << saturate);

    if( saturate )
    {
      answer.get().push_back(Tuple());
      return;
    }
  }

  // check if nspoil is true
  {
    // id of constant of saturate/spoil predicate
    ID saturate_pred = query.input[4];

    // get id of 0-ary atom
    OrdinaryAtom saturate_oatom(ID::MAINKIND_ATOM | ID::SUBKIND_ATOM_ORDINARYG);
    saturate_oatom.tuple.push_back(saturate_pred);
    ID saturate_atom = reg->storeOrdinaryGAtom(saturate_oatom);
    DBGLOG(DBG,"got saturate_pred=" << saturate_pred << " and saturate_atom=" << saturate_atom);

    // check if atom <saturate_pred> is true in interpretation
    bool saturate = query.interpretation->getFact(saturate_atom.address);
    LOG(DBG,"SaturationMetaAtom called with saturate=" << saturate);

    if( saturate )
    {
      answer.use();
      return;
    }
  }

  // get arguments
  const std::string& semantics = reg->getTermStringByID(query.input[0]);
  ID argRelId = query.input[1];
  ID attRelId = query.input[2];
  ID extRelId = query.input[3];

  // assemble facts from input
  std::stringstream s;
  {
    // add argumentation framework (att, arg) as predicates att/2 and arg/1
    // (ignore predicate name of given atoms)

    // TODO: we could do this more efficiently using extctx.edb->setFact(...); and not by parsing

    // arguments
    {
      PredicateMask& argMask = getPredicateMask(argRelId, reg);
      argMask.updateMask();
      InterpretationPtr argInt(new Interpretation(*query.interpretation));
      argInt->bit_and(*argMask.mask());
      for(auto begend = argInt->trueBits(); begend.first != begend.second; ++begend.first++)
      {
        auto bit_it = begend.first;
        const OrdinaryAtom& atom = argInt->getAtomToBit(bit_it);
        assert(atom.tuple.size() == 2);
        s << "arg(" << printToString<RawPrinter>(atom.tuple[1], reg) << ").\n";
      }
    }

    // attacks
    {
      PredicateMask& attMask = getPredicateMask(attRelId, reg);
      attMask.updateMask();
      InterpretationPtr attInt(new Interpretation(*query.interpretation));
      attInt->bit_and(*attMask.mask());
      for(auto begend = attInt->trueBits(); begend.first != begend.second; ++begend.first++)
      {
        auto bit_it = begend.first;
        const OrdinaryAtom& atom = attInt->getAtomToBit(bit_it);
        assert(atom.tuple.size() == 3);
        s << "att(" << printToString<RawPrinter>(atom.tuple[1], reg) << "," << printToString<RawPrinter>(atom.tuple[2], reg) << ").\n";
      }
    }

    // extension to check
    {
      PredicateMask& extMask = getPredicateMask(extRelId, reg);
      extMask.updateMask();
      InterpretationPtr extInt(new Interpretation(*query.interpretation));
      extInt->bit_and(*extMask.mask());
      for(auto begend = extInt->trueBits(); begend.first != begend.second; ++begend.first++)
      {
        auto bit_it = begend.first;
        const OrdinaryAtom& atom = extInt->getAtomToBit(bit_it);
        assert(atom.tuple.size() == 2);
        s << "ext(" << printToString<RawPrinter>(atom.tuple[1], reg) << ").\n";
      }
    }
  }

  // we use an extra registry for an external program
  ProgramCtx extctx;
  extctx.setupRegistry(RegistryPtr(new Registry));

  // build program
  InputProviderPtr input(new InputProvider);
  input->addStringInput(s.str(),"facts_from_predicate_input");
  input->addFileInput(semantics + ".encoding");

  // parse
  ModuleHexParser parser;
  parser.parse(input, extctx);

  DBGLOG(DBG,"after parsing input: idb and edb are" << std::endl << std::endl <<
      printManyToString<RawPrinter>(extctx.idb,"\n",extctx.registry()) << std::endl <<
      *extctx.edb << std::endl);

  // check if there is one answer set, if yes return true, false otherwise
  {
    typedef ASPSolverManager::SoftwareConfiguration<ASPSolver::DLVSoftware> DLVConfiguration;
    DLVConfiguration dlv;
    OrdinaryASPProgram program(extctx.registry(), extctx.idb, extctx.edb, extctx.maxint);
    ASPSolverManager mgr;
    ASPSolverManager::ResultsPtr res = mgr.solve(dlv, program);
    AnswerSet::Ptr firstAnswerSet = res->getNextAnswerSet();
    if( firstAnswerSet != 0 )
    {
      LOG(DBG,"got answer set " << *firstAnswerSet->interpretation);
      // true
      answer.get().push_back(Tuple());
    }
    else
    {
      LOG(DBG,"got no answer set!");
      // false (-> mark as used)
      answer.use();
    }
  }
}
    
class InputConverter:
	public PluginConverter
{
public:
  InputConverter(PluginCtxData& pcd):
		pcd(pcd) {}
  virtual ~InputConverter() {}

  virtual void convert(std::istream& i, std::ostream& o)
  {
    switch(pcd.mode)
    {
      case PluginCtxData::IDEAL:
        // just passthrough the input
        o << i.rdbuf();
        // add ideal encoding
        {
          std::ifstream inf("ideal.hex.encoding");
          o << inf.rdbuf();
        }
        break;
      default:
        throw std::runtime_error("input converter error unexpected mode!");
    }
  }

protected:
  PluginCtxData& pcd;
};

	//
	// A plugin must derive from PluginInterface
	//
	class ArguPlugin : public PluginInterface
    {
    public:
      typedef ArguPluginCtxData CtxData;

		public:
			ArguPlugin() 
			{
				setNameVersion(PACKAGE_TARNAME,ARGUPLUGIN_VERSION_MAJOR,ARGUPLUGIN_VERSION_MINOR,ARGUPLUGIN_VERSION_MICRO);
			}
		
			virtual std::vector<PluginAtomPtr> createAtoms(ProgramCtx& ctx) const
			{
				std::vector<PluginAtomPtr> ret;
			
				// return smart pointer with deleter (i.e., delete code compiled into this plugin)
				ret.push_back(PluginAtomPtr(new ArgSemExtAtom, PluginPtrDeleter<PluginAtom>()));
			
				return ret;
			}
      
			virtual void 
			processOptions(std::list<const char*>& pluginOptions, ProgramCtx& ctx);

      PluginConverterPtr
      createConverter(ProgramCtx& ctx)
      {
        PluginCtxData& pcd = ctx.getPluginData<ArguPlugin>();
        if( pcd.mode != PluginCtxData::DISABLED )
        {
          return PluginConverterPtr(new InputConverter(pcd));
        }
        return PluginConverterPtr();
      }
	};

void ArguPlugin::processOptions(std::list<const char*>& pluginOptions, ProgramCtx& ctx)
{
  PluginCtxData& pcd = ctx.getPluginData<ArguPlugin>();

  // look which mode, if any
  typedef std::list<const char*>::iterator Iterator;
  Iterator it;
  it = pluginOptions.begin();
  while( it != pluginOptions.end() )
  {
    bool processed = false;
    const std::string str(*it);
    if( str == "--argumode=ideal" )
    {
      pcd.mode = PluginCtxData::IDEAL;
      processed = true;
    }

    if( processed )
    {
      // return value of erase: element after it, maybe end()
      DBGLOG(DBG,"ArguPlugin successfully processed option " << str);
      it = pluginOptions.erase(it);
    }
    else
    {
      it++;
    }
  }
}
      
    
    
//
// now instantiate the plugin
//
ArguPlugin theArguPlugin;

} // namespace argu
} // namespace dlvhex

//
// let it be loaded by dlvhex!
//

IMPLEMENT_PLUGINABIVERSIONFUNCTION

// return plain C type s.t. all compilers and linkers will like this code
extern "C"
void * PLUGINIMPORTFUNCTION()
{
	return reinterpret_cast<void*>(& dlvhex::argu::theArguPlugin);
}


