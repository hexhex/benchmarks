
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

class ReachableAtom : public PluginAtom
{
public:

public:
	ReachableAtom():
		PluginAtom("reachable", true)
	{
		addInputPredicate();
		addInputConstant();
		addInputConstant();
		setOutputArity(2);

		prop.monotonicInputPredicates.push_back(0);
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
		assert(query.input.size() == 3);

		RegistryPtr reg = getRegistry();

		int sizeX = 0;
		int sizeY = 0;

		// determine size of the maze
		DBGLOG(DBG, "Determining size of maze");
		bm::bvector<>::enumerator en = query.interpretation->getStorage().first();
		bm::bvector<>::enumerator en_end = query.interpretation->getStorage().end();
		while (en < en_end){
			const OrdinaryAtom& ogatom = reg->ogatoms.getByAddress(*en);
			sizeX = ogatom.tuple[1].address > sizeX ? ogatom.tuple[1].address : sizeX;
			sizeY = ogatom.tuple[2].address > sizeX ? ogatom.tuple[2].address : sizeX;
			en++;
		}

		// allocate maze
		DBGLOG(DBG, "Allocating maze");
		int** maze = new int*[sizeX];
		for (int x = 0; x < sizeX; ++x){
			maze[x] = new int[sizeY];
			for (int y = 0; y < sizeY; ++y){
				maze[x][y] = 0;
			}
		}

		DBGLOG(DBG, "Interpreting maze");
		Term tS(ID::MAINKIND_TERM | ID::SUBKIND_TERM_CONSTANT, "s");
		Term tU(ID::MAINKIND_TERM | ID::SUBKIND_TERM_CONSTANT, "u");
		Term tD(ID::MAINKIND_TERM | ID::SUBKIND_TERM_CONSTANT, "d");
		Term tL(ID::MAINKIND_TERM | ID::SUBKIND_TERM_CONSTANT, "l");
		Term tR(ID::MAINKIND_TERM | ID::SUBKIND_TERM_CONSTANT, "r");
		ID tSid = reg->storeTerm(tS);
		ID tUid = reg->storeTerm(tU);
		ID tDid = reg->storeTerm(tD);
		ID tLid = reg->storeTerm(tL);
		ID tRid = reg->storeTerm(tR);

		// read maze
		en = query.interpretation->getStorage().first();
		en_end = query.interpretation->getStorage().end();
		while (en < en_end){
			const OrdinaryAtom& ogatom = reg->ogatoms.getByAddress(*en);
			if (ogatom.tuple[3] == tUid){
				maze[ogatom.tuple[1].address - 1][ogatom.tuple[2].address - 1] |= 1;
			}
			else if (ogatom.tuple[3] == tDid){
				maze[ogatom.tuple[1].address - 1][ogatom.tuple[2].address - 1] |= 2;
			}
			else if (ogatom.tuple[3] == tLid){
				maze[ogatom.tuple[1].address - 1][ogatom.tuple[2].address - 1] |= 4;
			}
			else if (ogatom.tuple[3] == tRid){
				maze[ogatom.tuple[1].address - 1][ogatom.tuple[2].address - 1] |= 8;
			}
			else if (ogatom.tuple[3] == tSid){
			}
			else{
				throw PluginError("Invalid maze");
			}
			en++;
		}

		// compute reachable fields
		DBGLOG(DBG, "Computing reachable fields");
		std::set<std::pair<int, int> > reachable;
		dfs(query.input[1].address - 1, query.input[2].address - 1, sizeX, sizeY, maze, reachable);

		// copy reachable fields to output
		DBGLOG(DBG, "Creating output");
		typedef std::pair<int, int> Field;
		BOOST_FOREACH (Field f, reachable){
			Tuple out;
			out.push_back(ID::termFromInteger(f.first + 1));
			out.push_back(ID::termFromInteger(f.second + 1));
			answer.get().push_back(out); 
		}

		// learning
		if (nogoods){
			// for all fields on the border between the reachable and the unreachable area
			Nogood ng;
			for (int x = 0; x < sizeX; ++x){
				for (int y = 0; y < sizeY; ++y){
					if (std::find(reachable.begin(), reachable.end(), std::pair<int, int>(x, y)) != reachable.end()){
						// all missing connections on the border together form a reason for the non-existence of a path to unreachable fields
						if (x > 0 && std::find(reachable.begin(), reachable.end(), std::pair<int, int>(x - 1, y)) == reachable.end()){
							if (maze[x][y] | 4 == 0){
								OrdinaryAtom oatom(ID::MAINKIND_ATOM | ID::SUBKIND_ATOM_ORDINARYG);
								oatom.tuple.push_back(query.input[0]);
								oatom.tuple.push_back(ID::termFromInteger(x + 1));
								oatom.tuple.push_back(ID::termFromInteger(y + 1));
								oatom.tuple.push_back(tLid);
								ng.insert(NogoodContainer::createLiteral(reg->storeOrdinaryGAtom(oatom).address, false));
							}
							else if (maze[x - 1][y] | 8 == 0){
								OrdinaryAtom oatom(ID::MAINKIND_ATOM | ID::SUBKIND_ATOM_ORDINARYG);
								oatom.tuple.push_back(query.input[0]);
								oatom.tuple.push_back(ID::termFromInteger(x));
								oatom.tuple.push_back(ID::termFromInteger(y + 1));
								oatom.tuple.push_back(tRid);
								ng.insert(NogoodContainer::createLiteral(reg->storeOrdinaryGAtom(oatom).address, false));
							}
						}
						if (y > 0 && std::find(reachable.begin(), reachable.end(), std::pair<int, int>(x, y - 1)) == reachable.end()){
							if (maze[x][y] | 1 == 0){
								OrdinaryAtom oatom(ID::MAINKIND_ATOM | ID::SUBKIND_ATOM_ORDINARYG);
								oatom.tuple.push_back(query.input[0]);
								oatom.tuple.push_back(ID::termFromInteger(x + 1));
								oatom.tuple.push_back(ID::termFromInteger(y + 1));
								oatom.tuple.push_back(tUid);
								ng.insert(NogoodContainer::createLiteral(reg->storeOrdinaryGAtom(oatom).address, false));
							}
							else if (maze[x][y - 1] | 2 == 0){
								OrdinaryAtom oatom(ID::MAINKIND_ATOM | ID::SUBKIND_ATOM_ORDINARYG);
								oatom.tuple.push_back(query.input[0]);
								oatom.tuple.push_back(ID::termFromInteger(x + 1));
								oatom.tuple.push_back(ID::termFromInteger(y));
								oatom.tuple.push_back(tDid);
								ng.insert(NogoodContainer::createLiteral(reg->storeOrdinaryGAtom(oatom).address, false));
							}
						}
						if (x < sizeX - 1 && std::find(reachable.begin(), reachable.end(), std::pair<int, int>(x + 1, y)) == reachable.end()){
							if (maze[x][y] | 8 == 0){
								OrdinaryAtom oatom(ID::MAINKIND_ATOM | ID::SUBKIND_ATOM_ORDINARYG);
								oatom.tuple.push_back(query.input[0]);
								oatom.tuple.push_back(ID::termFromInteger(x + 1));
								oatom.tuple.push_back(ID::termFromInteger(y + 1));
								oatom.tuple.push_back(tRid);
								ng.insert(NogoodContainer::createLiteral(reg->storeOrdinaryGAtom(oatom).address, false));
							}
							else if (maze[x + 1][y] | 4 == 0){
								OrdinaryAtom oatom(ID::MAINKIND_ATOM | ID::SUBKIND_ATOM_ORDINARYG);
								oatom.tuple.push_back(query.input[0]);
								oatom.tuple.push_back(ID::termFromInteger(x + 2));
								oatom.tuple.push_back(ID::termFromInteger(y + 1));
								oatom.tuple.push_back(tLid);
								ng.insert(NogoodContainer::createLiteral(reg->storeOrdinaryGAtom(oatom).address, false));
							}
						}
						if (y < sizeY - 1 && std::find(reachable.begin(), reachable.end(), std::pair<int, int>(x, y + 1)) == reachable.end()){
							if (maze[x][y] | 2 == 0){
								OrdinaryAtom oatom(ID::MAINKIND_ATOM | ID::SUBKIND_ATOM_ORDINARYG);
								oatom.tuple.push_back(query.input[0]);
								oatom.tuple.push_back(ID::termFromInteger(x + 1));
								oatom.tuple.push_back(ID::termFromInteger(y + 1));
								oatom.tuple.push_back(tDid);
								ng.insert(NogoodContainer::createLiteral(reg->storeOrdinaryGAtom(oatom).address, false));
							}
							else if (maze[x][y + 1] | 1 == 0){
								OrdinaryAtom oatom(ID::MAINKIND_ATOM | ID::SUBKIND_ATOM_ORDINARYG);
								oatom.tuple.push_back(query.input[0]);
								oatom.tuple.push_back(ID::termFromInteger(x + 1));
								oatom.tuple.push_back(ID::termFromInteger(y + 2));
								oatom.tuple.push_back(tUid);
								ng.insert(NogoodContainer::createLiteral(reg->storeOrdinaryGAtom(oatom).address, false));
							}
						}
					}
				}
			}

			// store this reason for all unreachable fields
			for (int x = 0; x < sizeX; ++x){
				for (int y = 0; y < sizeY; ++y){
					if (std::find(reachable.begin(), reachable.end(), std::pair<int, int>(x, y)) == reachable.end()){
						Nogood ng2 = ng;
						Tuple t;
						t.push_back(ID::termFromInteger(x + 1));
						t.push_back(ID::termFromInteger(y + 1));
						ng2.insert(getOutputAtom(ctx, nogoods, query, t, true));
						nogoods->addNogood(ng2);
					}
				}
			}

			// due to monotonicity, the existing connections together for a reason for the existence of a path to all reachable fields
			int s = nogoods->getNogoodCount();
			learnFromInputOutputBehavior(ctx, nogoods, query, this->prop, answer);
		}

		// destroy maze
		DBGLOG(DBG, "Deleting maze");
		for (int x = 0; x < sizeX; ++x){
			delete []maze[x];
		}
		delete []maze;
	}

	void dfs(int x, int y, int sizeX, int sizeY, int** maze, std::set<std::pair<int, int> >& reachable){
		// out of bounds?
		if (x < 0 || y < 0 || x >= sizeX || y >= sizeY) return;

		// is the field already marked as reachable?
		int s = reachable.size();
		reachable.insert(std::pair<int, int>(x, y));
		if (reachable.size() == s) return;

		// visit all newly reachable fields
		if (maze[x][y] & 1) dfs(x, y - 1, sizeX, sizeY, maze, reachable);
		if (maze[x][y] & 2) dfs(x, y + 1, sizeX, sizeY, maze, reachable);
		if (maze[x][y] & 4) dfs(x - 1, y, sizeX, sizeY, maze, reachable);
		if (maze[x][y] & 8) dfs(x + 1, y, sizeX, sizeY, maze, reachable);
	}
};

class MazePlugin : public PluginInterface
{
public:

public:
	MazePlugin() 
	{
		setNameVersion(PACKAGE_TARNAME,
				MAZEPLUGIN_VERSION_MAJOR,MAZEPLUGIN_VERSION_MINOR,MAZEPLUGIN_VERSION_MICRO);
	}

	virtual std::vector<PluginAtomPtr> createAtoms(ProgramCtx& ctx) const
	{
		std::vector<PluginAtomPtr> ret;
	
		// return smart pointer with deleter (i.e., delete code compiled into this plugin)
		ret.push_back(PluginAtomPtr(
					new ReachableAtom(),
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


