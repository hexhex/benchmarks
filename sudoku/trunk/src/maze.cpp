
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

#include <boost/graph/graph_traits.hpp>
#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/dijkstra_shortest_paths.hpp>

#include <string>
#include <sstream>
#include <fstream>
#include <cstdio>

using namespace boost;

namespace dlvhex {
namespace benchmark {

class SudokuValidityAtom : public PluginAtom
{
private:
	RegistryPtr reg;

public:
	SudokuValidityAtom():
		PluginAtom("sudokuvalidity", false)
	{
		addInputPredicate();
		setOutputArity(0);
	}

	virtual void
	retrieve(const Query& query, Answer& answer) throw (PluginError)
	{
		// should never be called
		assert(false);
	}

	virtual void
	retrieve(const Query& query, Answer& answer, ProgramCtx* ctx, NogoodContainerPtr nogoods) throw (PluginError)
	{
		assert(query.input.size() == 1);
		reg = getRegistry();

		// read sudoku
		DBGLOG(DBG, "Reading sudoku");
		int sudoku[9][9];
		for (int x = 0; x < 9; ++x){
			for (int y = 0; y < 9; ++y){
				sudoku[x][y] = 0;
			}
		}
		bm::bvector<>::enumerator en = query.interpretation->getStorage().first();
		bm::bvector<>::enumerator en_end = query.interpretation->getStorage().end();
		while (en < en_end){
			const OrdinaryAtom& ogatom = reg->ogatoms.getByAddress(*en);

			if (ogatom.tuple.size() != 4) throw PluginError("Sudoku-defining predicate must be of arity 3");
			if (ogatom.tuple[1].address < 1 || ogatom.tuple[1].address > 9 ||
			    ogatom.tuple[2].address < 1 || ogatom.tuple[2].address > 9 ||
			    ogatom.tuple[3].address < 1 || ogatom.tuple[3].address > 9) throw PluginError("Sudoku-defining predicate must only use numbers 1-9");

			sudoku[ogatom.tuple[1].address - 1][ogatom.tuple[2].address - 1] = ogatom.tuple[3].address;
			en++;
		}

		// check if numbers are unique in a row
		DBGLOG(DBG, "Checking uniqueness in a row");
		for (int y = 0; y < 9; ++y){
			int occurs[] = {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1};
			for (int x = 0; x < 9; ++x){
				if (sudoku[x][y] != 0){
					if (occurs[sudoku[x][y]] != -1){
						// duplicate entry
						if (nogoods){
							OrdinaryAtom at1(ID::MAINKIND_ATOM | ID::SUBKIND_ATOM_ORDINARYG);
							at1.tuple.push_back(query.input[0]);
							at1.tuple.push_back(ID::termFromInteger(occurs[sudoku[x][y]] + 1));
							at1.tuple.push_back(ID::termFromInteger(y + 1));
							at1.tuple.push_back(ID::termFromInteger(sudoku[x][y]));

							OrdinaryAtom at2(ID::MAINKIND_ATOM | ID::SUBKIND_ATOM_ORDINARYG);
							at2.tuple.push_back(query.input[0]);
							at2.tuple.push_back(ID::termFromInteger(x + 1));
							at2.tuple.push_back(ID::termFromInteger(y + 1));
							at2.tuple.push_back(ID::termFromInteger(sudoku[x][y]));

							Tuple t;
							Nogood ng;
							ng.insert(NogoodContainer::createLiteral(reg->storeOrdinaryGAtom(at1).address, true));
							ng.insert(NogoodContainer::createLiteral(reg->storeOrdinaryGAtom(at2).address, true));
							ng.insert(NogoodContainer::createLiteral(getOutputAtom(ctx, nogoods, query, t, true)));
							nogoods->addNogood(ng);
//std::cout << "Learned nogood: " << ng.getStringRepresentation(reg) << std::endl;
						}
						DBGLOG(DBG, sudoku[x][y] << " is not unique in row " << y);
						return;
					}else{
						occurs[sudoku[x][y]] = x;
					}
				}
			}
		}

		// check if numbers are unique in a column
		DBGLOG(DBG, "Checking uniqueness in a column");
		for (int x = 0; x < 9; ++x){
			int occurs[] = {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1};
			for (int y = 0; y < 9; ++y){
				if (sudoku[x][y] != 0){
					if (occurs[sudoku[x][y]] != -1){
						// duplicate entry
						if (nogoods){
							OrdinaryAtom at1(ID::MAINKIND_ATOM | ID::SUBKIND_ATOM_ORDINARYG);
							at1.tuple.push_back(query.input[0]);
							at1.tuple.push_back(ID::termFromInteger(x + 1));
							at1.tuple.push_back(ID::termFromInteger(occurs[sudoku[x][y]] + 1));
							at1.tuple.push_back(ID::termFromInteger(sudoku[x][y]));

							OrdinaryAtom at2(ID::MAINKIND_ATOM | ID::SUBKIND_ATOM_ORDINARYG);
							at2.tuple.push_back(query.input[0]);
							at2.tuple.push_back(ID::termFromInteger(x + 1));
							at2.tuple.push_back(ID::termFromInteger(y + 1));
							at2.tuple.push_back(ID::termFromInteger(sudoku[x][y]));

							Tuple t;
							Nogood ng;
							ng.insert(NogoodContainer::createLiteral(reg->storeOrdinaryGAtom(at1).address, true));
							ng.insert(NogoodContainer::createLiteral(reg->storeOrdinaryGAtom(at2).address, true));
							ng.insert(NogoodContainer::createLiteral(getOutputAtom(ctx, nogoods, query, t, true)));
							nogoods->addNogood(ng);
//std::cout << "Learned nogood: " << ng.getStringRepresentation(reg) << std::endl;

						}
						DBGLOG(DBG, sudoku[x][y] << " is not unique in column " << x);
						return;
					}else{
						occurs[sudoku[x][y]] = y;
					}
				}
			}
		}

		// check if numbers are unique in a field
		DBGLOG(DBG, "Checking uniqueness in a field");
		for (int f = 0; f < 9; ++f){
			int occurs[] = {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1};
			for (int c = 0; c < 9; ++c){
				int x = (f % 3) * 3 + c % 3;
				int y = (f / 3) * 3 + c / 3;
				if (sudoku[x][y] != 0){
					if (occurs[sudoku[x][y]] != -1){
						// duplicate entry
						if (nogoods){
							OrdinaryAtom at1(ID::MAINKIND_ATOM | ID::SUBKIND_ATOM_ORDINARYG);
							int x2 = (f % 3) * 3 + occurs[sudoku[x][y]] % 3;
							int y2 = (f / 3) * 3 + occurs[sudoku[x][y]] / 3;
							at1.tuple.push_back(query.input[0]);
							at1.tuple.push_back(ID::termFromInteger(x2 + 1));
							at1.tuple.push_back(ID::termFromInteger(y2 + 1));
							at1.tuple.push_back(ID::termFromInteger(sudoku[x][y]));

							OrdinaryAtom at2(ID::MAINKIND_ATOM | ID::SUBKIND_ATOM_ORDINARYG);
							at2.tuple.push_back(query.input[0]);
							at2.tuple.push_back(ID::termFromInteger(x + 1));
							at2.tuple.push_back(ID::termFromInteger(y + 1));
							at2.tuple.push_back(ID::termFromInteger(sudoku[x][y]));

							Tuple t;
							Nogood ng;
							ng.insert(NogoodContainer::createLiteral(reg->storeOrdinaryGAtom(at1).address, true));
							ng.insert(NogoodContainer::createLiteral(reg->storeOrdinaryGAtom(at2).address, true));
							ng.insert(NogoodContainer::createLiteral(getOutputAtom(ctx, nogoods, query, t, true)));
							nogoods->addNogood(ng);
//std::cout << "Learned nogood: " << ng.getStringRepresentation(reg) << std::endl;

						}
						DBGLOG(DBG, sudoku[x][y] << " is not unique in field " << f);
						return;
					}else{
						occurs[sudoku[x][y]] = c;
					}
				}
			}
		}

		// valid
		Tuple out;
		answer.get().push_back(out); 
	}
};

class MazePlugin : public PluginInterface
{
public:

public:
	MazePlugin() 
	{
		setNameVersion(PACKAGE_TARNAME,
				SUDOKUPLUGIN_VERSION_MAJOR,SUDOKUPLUGIN_VERSION_MINOR,SUDOKUPLUGIN_VERSION_MICRO);
	}

	virtual std::vector<PluginAtomPtr> createAtoms(ProgramCtx& ctx) const
	{
		std::vector<PluginAtomPtr> ret;
	
		// return smart pointer with deleter (i.e., delete code compiled into this plugin)
		ret.push_back(PluginAtomPtr(
					new SudokuValidityAtom(),
					PluginPtrDeleter<PluginAtom>()));

		return ret;
	}
};

    
//
// now instantiate the plugin
//
MazePlugin theMazePlugin;

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
	return reinterpret_cast<void*>(& dlvhex::benchmark::theMazePlugin);
}


