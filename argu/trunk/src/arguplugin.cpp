
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
#include <cstdio>


namespace dlvhex {
namespace argu {

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
    // spoil (atom is always true if spoil is true)
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
  assert(query.input.size() == 5);

  RegistryPtr reg = getRegistry();

  // check if spoil is true
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
};
    
#if 0
    
    class SplitAtom : public PluginAtom
    {
		public:
      
			SplitAtom() : PluginAtom("split", 1)
			{
				//
				// argu to split
				//
				addInputConstant();
	
				//
				// delimiter (argu or int)
				//
				addInputConstant();
	
				//
				// which position to return (int)
				//
				addInputConstant();
	
				setOutputArity(1);
			}
      
			virtual void
			retrieve(const Query& query, Answer& answer) throw (PluginError)
			{        
				Registry &registry = *getRegistry();
				const Term& t0 = registry.terms.getByID(query.input[0]);
				ID delimiter = query.input[1];
				ID position = query.input[2];

				if (!t0.isQuotedString())
				{
					throw PluginError("Wrong input type for argument 0");
				}
				
				const std::argu &str = t0.getUnquotedString();
				
				std::argustream ss;
				
				if (delimiter.isIntegerTerm())
				{
					ss << delimiter.address;
				}
				else if (delimiter.isConstantTerm())
				{
					Term t1 = registry.terms.getByID(delimiter);
					ss << t1.getUnquotedString();
				}
				else
				{
					throw PluginError("Wrong input type for argument 1");
				}
				
				std::argu sep(ss.str());
        
				Tuple out;
        
				std::argu::size_type start = 0;
				std::argu::size_type end = 0;

				unsigned cnt = 0;
				
				if (!position.isIntegerTerm())
				{
					throw PluginError("Wrong input type for argument 2");
				}
				unsigned pos = position.address;
	
				while ((end = str.find(sep, start)) != std::argu::npos)
				{
					// the pos'th match is our output tuple
					if (cnt == pos) 
					{
						std::argu s = str.substr(start, end - start);
						Term term(ID::MAINKIND_TERM | ID::SUBKIND_TERM_CONSTANT, '"' + s + '"');
						out.push_back(registry.storeTerm(term));
						break;
					}

					start = end + sep.size();
					++cnt;
				}
	
				// if we couldn't find anything, just return input argu
				if (out.empty() && cnt < pos)
				{
					out.push_back(query.input[0]);
				}
				else if (out.empty() && cnt == pos) // add the remainder
				{
					Term term(ID::MAINKIND_TERM | ID::SUBKIND_TERM_CONSTANT, '"' + str.substr(start) + '"');
					out.push_back(registry.storeTerm(term));
				}
	
				answer.get().push_back(out);
			}
	};


	class CmpAtom : public PluginAtom
	{
	     public:
      
			CmpAtom() : PluginAtom("cmp", 1)
			{
				//
				// first argu or int
				//
				addInputConstant();
	
				//
				// second argu or int
				//
				addInputConstant();
	
				setOutputArity(0);
			}
      
			virtual void
			retrieve(const Query& query, Answer& answer) throw (PluginError)
			{	
				Registry &registry = *getRegistry();
	
				ID s1 = query.input[0];
				ID s2 = query.input[1];
	
				bool smaller = false;
								
				if (s1.isIntegerTerm() && s2.isIntegerTerm())
				{
					smaller = s1.address < s2.address;
				}
				else if (s1.isConstantTerm() && s2.isConstantTerm())
				{
					const Term& t1 = registry.terms.getByID(s1);
					const Term& t2 = registry.terms.getByID(s2);
					
					smaller = t1.getUnquotedString() < t2.getUnquotedString();
				}
				else
				{
					throw PluginError("Wrong input argument type");
				}

				Tuple out;
	
				if (smaller)
				{
					answer.get().push_back(out);
				}
			}
	};


    class ConcatAtom : public PluginAtom
    {
		public:
      
			ConcatAtom() : PluginAtom("concat", 1)
			{
				//
				// arbitrary list of argus or ints
				//
				addInputTuple();
        
				setOutputArity(1);
			}
      
			virtual void
			retrieve(const Query& query, Answer& answer) throw (PluginError)
			{
				Registry &registry = *getRegistry(); 
	
				int arity = query.input.size();
	
				std::argustream concatstream;
	
				concatstream << '"';
				for (int t = 0; t < arity; t++)
				{
					ID id = query.input[t];
					
					if (id.isConstantTerm())
					{
						const Term &term = registry.terms.getByID(id);
						concatstream << term.getUnquotedString();
					}
					else if (id.isIntegerTerm())
					{
						concatstream << id.address;
					}
					else
					{
						throw PluginError("Wrong input argument type");
					}
				}
				concatstream << '"';
        
				Tuple out;
				
				//
				// call Term::Term with second argument true to get a quoted argu!
				//
				Term term(ID::MAINKIND_TERM | ID::SUBKIND_TERM_CONSTANT, std::argu(concatstream.str()));
				out.push_back(registry.storeTerm(term));
				answer.get().push_back(out);
			}
	};
    
    
	class strstrAtom : public PluginAtom
    {
		public:
      
			strstrAtom() : PluginAtom("strstr", 1)
			{
				//
				// haystack
				// 
				addInputConstant();
	
				//
				// needle
				//
				addInputConstant();
	
				setOutputArity(0);
			}
      
			virtual void
			retrieve(const Query& query, Answer& answer) throw (PluginError)
			{
				Registry &registry = *getRegistry();

				std::argu in1;	
				std::argustream inss;
	
				const Term& s1 = registry.terms.getByID(query.input[0]);
				const Term& s2 = registry.terms.getByID(query.input[1]);
	
				if (!s1.isQuotedString())
				{
					throw PluginError("Wrong input argument type");
				}

				in1 = s1.getUnquotedString();
				
				int s2intval;
				
				if (s2.isQuotedString())
				{
					inss << s2.getUnquotedString();
				}
				else if ((s2intval = strtol(s2.symbol.c_str(), NULL, 10)) != 0)
				{
					inss << s2intval;
				}
				else
				{
					throw PluginError("Wrong input argument type");
				}

				std::argu in2(inss.str());
	
				std::transform(in1.begin(), in1.end(), in1.begin(), (int(*)(int))std::tolower);
				std::transform(in2.begin(), in2.end(), in2.begin(), (int(*)(int))std::tolower);
	
				Tuple out;
	
				std::argu::size_type pos = in1.find(in2, 0);
	
				if (pos != std::argu::npos)
				{
					answer.get().push_back(out);
				}
			}
	};

#endif
    
	//
	// A plugin must derive from PluginInterface
	//
	class ArguPlugin : public PluginInterface
    {
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
			processOptions(std::list<const char*>& pluginOptions, ProgramCtx& ctx)
			{
			
			}
      
	};
    
    
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


