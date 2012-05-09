
//
// this include is necessary
//

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif /* HAVE_CONFIG_H */

#include <dlvhex2/PluginInterface.h>
#include <dlvhex2/Term.h>
#include <dlvhex2/Registry.h>

#include <string>
#include <sstream>
#include <cstdio>


namespace dlvhex {
  namespace string {

    class ShaAtom : public PluginAtom
    {
		public:
			ShaAtom() : PluginAtom("sha1sum", 1)
			{
				//
				// input string
				//
				addInputConstant();
				
				setOutputArity(1);
			}
      
			virtual void
			retrieve(const Query& query, Answer& answer) throw (PluginError)
			{
				Registry &registry = *getRegistry();
				const Term& term = registry.terms.getByID(query.input[0]);

				if (!term.isQuotedString())
				{
					throw PluginError("Wrong input argument type");
				}
	
				const std::string& in = term.getUnquotedString();
				
				FILE *pp;
				char VBUFF[1024];
				
				std::string execstr("echo \"" + in + "\" | sha1sum | cut -d\" \" -f1");
	
				std::stringstream result;
	
				if ((pp = popen(execstr.c_str(), "r")) == NULL)
				{
					throw PluginError("sha1sum system call failed");
				}
	
				if (fgets(VBUFF, 1024, pp) == NULL)
				{
					throw PluginError("Cannot read from sha1sum pipe");
				}
	
				result << VBUFF;
	
				pclose(pp);
	
				std::string res(result.str());
	
				res.erase(res.size() - 1);
	
				Tuple out;
				Term newterm(ID::MAINKIND_TERM | ID::SUBKIND_TERM_CONSTANT, '"'+res+'"');
				out.push_back(registry.storeTerm(newterm));
				answer.get().push_back(out); 
			}
	};
    
    
    class SplitAtom : public PluginAtom
    {
		public:
      
			SplitAtom() : PluginAtom("split", 1)
			{
				//
				// string to split
				//
				addInputConstant();
	
				//
				// delimiter (string or int)
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
				
				const std::string &str = t0.getUnquotedString();
				
				std::stringstream ss;
				
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
				
				std::string sep(ss.str());
        
				Tuple out;
        
				std::string::size_type start = 0;
				std::string::size_type end = 0;

				unsigned cnt = 0;
				
				if (!position.isIntegerTerm())
				{
					throw PluginError("Wrong input type for argument 2");
				}
				unsigned pos = position.address;
	
				while ((end = str.find(sep, start)) != std::string::npos)
				{
					// the pos'th match is our output tuple
					if (cnt == pos) 
					{
						std::string s = str.substr(start, end - start);
						Term term(ID::MAINKIND_TERM | ID::SUBKIND_TERM_CONSTANT, '"' + s + '"');
						out.push_back(registry.storeTerm(term));
						break;
					}

					start = end + sep.size();
					++cnt;
				}
	
				// if we couldn't find anything, just return input string
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
				// first string or int
				//
				addInputConstant();
	
				//
				// second string or int
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
				// arbitrary list of strings or ints
				//
				addInputTuple();
        
				setOutputArity(1);
			}
      
			virtual void
			retrieve(const Query& query, Answer& answer) throw (PluginError)
			{
				Registry &registry = *getRegistry(); 
	
				int arity = query.input.size();
	
				std::stringstream concatstream;
	
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
				// call Term::Term with second argument true to get a quoted string!
				//
				Term term(ID::MAINKIND_TERM | ID::SUBKIND_TERM_CONSTANT, std::string(concatstream.str()));
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

				std::string in1;	
				std::stringstream inss;
	
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

				std::string in2(inss.str());
	
				std::transform(in1.begin(), in1.end(), in1.begin(), (int(*)(int))std::tolower);
				std::transform(in2.begin(), in2.end(), in2.begin(), (int(*)(int))std::tolower);
	
				Tuple out;
	
				std::string::size_type pos = in1.find(in2, 0);
	
				if (pos != std::string::npos)
				{
					answer.get().push_back(out);
				}
			}
	};

    
    
	//
	// A plugin must derive from PluginInterface
	//
	class StringPlugin : public PluginInterface
    {
		public:
      
			StringPlugin() 
			{
				setNameVersion(PACKAGE_TARNAME,STRINGPLUGIN_VERSION_MAJOR,STRINGPLUGIN_VERSION_MINOR,STRINGPLUGIN_VERSION_MICRO);
			}
		
			virtual std::vector<PluginAtomPtr> createAtoms(ProgramCtx&) const
			{
				std::vector<PluginAtomPtr> ret;
			
				// return smart pointer with deleter (i.e., delete code compiled into this plugin)
				ret.push_back(PluginAtomPtr(new ShaAtom, PluginPtrDeleter<PluginAtom>()));
				ret.push_back(PluginAtomPtr(new SplitAtom, PluginPtrDeleter<PluginAtom>()));
				ret.push_back(PluginAtomPtr(new CmpAtom, PluginPtrDeleter<PluginAtom>()));
				ret.push_back(PluginAtomPtr(new ConcatAtom, PluginPtrDeleter<PluginAtom>()));
				ret.push_back(PluginAtomPtr(new strstrAtom, PluginPtrDeleter<PluginAtom>()));
			
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
    StringPlugin theStringPlugin;
    
  } // namespace string
} // namespace dlvhex

//
// let it be loaded by dlvhex!
//

IMPLEMENT_PLUGINABIVERSIONFUNCTION

// return plain C type s.t. all compilers and linkers will like this code
extern "C"
void * PLUGINIMPORTFUNCTION()
{
	return reinterpret_cast<void*>(& dlvhex::string::theStringPlugin);
}


