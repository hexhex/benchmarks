
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

class ReachableAtom : public PluginAtom
{
private:
	RegistryPtr reg;

	ID tSid, tUid, tDid, tLid, tRid;

	class Maze{
	public:
		static const int UP_MASK = 1;
		static const int DOWN_MASK = 2;
		static const int LEFT_MASK = 4;
		static const int RIGHT_MASK = 8;

	private:
		int sizeX, sizeY;
		int** maze;
		bool** reachable;
		int** dfstree;

		void dfs_r(int x, int y){
			// out of bounds?
			if (x < 0 || y < 0 || x >= sizeX || y >= sizeY) return;

			// is the field already marked as reachable?
			if (reachable[x][y]) return;
			reachable[x][y] = true;

			// visit all newly reachable fields
			if (y > 0 && maze[x][y] & UP_MASK && maze[x][y - 1] & DOWN_MASK){
				if (!reachable[x][y - 1]){
					dfstree[x][y] |= UP_MASK;
					dfstree[x][y - 1] |= DOWN_MASK;
					dfs_r(x, y - 1);
				}
			}
			if (y < sizeY - 1 && maze[x][y] & DOWN_MASK && maze[x][y + 1] & UP_MASK){
				if (!reachable[x][y + 1]){
					dfstree[x][y] |= DOWN_MASK;
					dfstree[x][y + 1] |= UP_MASK;
					dfs_r(x, y + 1);
				}
			}
			if (x > 0 && maze[x][y] & LEFT_MASK && maze[x - 1][y] & RIGHT_MASK){
				if (!reachable[x - 1][y]){
					dfstree[x][y] |= LEFT_MASK;
					dfstree[x - 1][y] |= RIGHT_MASK;
					dfs_r(x - 1, y);
				}
			}
			if (x < sizeX - 1 && maze[x][y] & RIGHT_MASK && maze[x + 1][y] & LEFT_MASK){
				if (!reachable[x + 1][y]){
					dfstree[x][y] |= RIGHT_MASK;
					dfstree[x + 1][y] |= LEFT_MASK;
					dfs_r(x + 1, y);
				}
			}
		}

	public:
		Maze(ReachableAtom& ra, InterpretationConstPtr intr, int timestamp = -1){

			sizeX = 0;
			sizeY = 0;

			// determine size of the maze
			DBGLOG(DBG, "Determining size of maze");
			bm::bvector<>::enumerator en = intr->getStorage().first();
			bm::bvector<>::enumerator en_end = intr->getStorage().end();
			while (en < en_end){
				const OrdinaryAtom& ogatom = ra.reg->ogatoms.getByAddress(*en);
				if (timestamp != -1 && ogatom.tuple.size() != 5) throw PluginError("Maze-defining predicate must be of arity 4 if timestamp is given");
				if (timestamp == -1 && ogatom.tuple.size() != 4) throw PluginError("Maze-defining predicate must be of arity 3 if timestamp is not given");
				if (timestamp == -1 || ogatom.tuple[4].address == timestamp){
					sizeX = ogatom.tuple[1].address > sizeX ? ogatom.tuple[1].address : sizeX;
					sizeY = ogatom.tuple[2].address > sizeX ? ogatom.tuple[2].address : sizeX;
				}
				en++;
			}

			// allocate maze
			DBGLOG(DBG, "Allocating maze");
			maze = new int*[sizeX];
			reachable = new bool*[sizeX];
			dfstree = new int*[sizeX];
			for (int x = 0; x < sizeX; ++x){
				maze[x] = new int[sizeY];
				reachable[x] = new bool[sizeY];
				dfstree[x] = new int[sizeY];
				for (int y = 0; y < sizeY; ++y){
					maze[x][y] = 0;
				}
			}

			DBGLOG(DBG, "Interpreting maze");

			// read maze
			en = intr->getStorage().first();
			en_end = intr->getStorage().end();
			while (en < en_end){
				const OrdinaryAtom& ogatom = ra.reg->ogatoms.getByAddress(*en);
				if (timestamp == -1 || ogatom.tuple[4].address == timestamp){
					if (ogatom.tuple[3] == ra.tUid){
						maze[ogatom.tuple[1].address - 1][ogatom.tuple[2].address - 1] |= UP_MASK;
					}
					else if (ogatom.tuple[3] == ra.tDid){
						maze[ogatom.tuple[1].address - 1][ogatom.tuple[2].address - 1] |= DOWN_MASK;
					}
					else if (ogatom.tuple[3] == ra.tLid){
						maze[ogatom.tuple[1].address - 1][ogatom.tuple[2].address - 1] |= LEFT_MASK;
					}
					else if (ogatom.tuple[3] == ra.tRid){
						maze[ogatom.tuple[1].address - 1][ogatom.tuple[2].address - 1] |= RIGHT_MASK;
					}
					else if (ogatom.tuple[3] == ra.tSid){
					}
					else{
						throw PluginError("Invalid maze");
					}
				}
				en++;
			}
		}

		virtual ~Maze(){
			// destroy maze
			DBGLOG(DBG, "Deleting maze");
			for (int x = 0; x < sizeX; ++x){
				delete []maze[x];
				delete []reachable[x];
				delete []dfstree[x];
			}
			delete []maze;
			delete []reachable;
			delete []dfstree;
		}

		void dfs(int x, int y){
			assert (x >= 1 && x <= sizeX);
			assert (y >= 1 && x <= sizeY);

			// reset
			for (int xi = 0; xi < sizeX; ++xi){
				for (int yi = 0; yi < sizeY; ++yi){
					reachable[xi][yi] = false;
					dfstree[xi][yi] = 0;
				}
			}

			// run
			dfs_r(x - 1, y - 1);
		}

		void findpath(int startX, int startY, int destX, int destY){
			assert (startX >= 1 && startX <= sizeX);
			assert (startY >= 1 && startY <= sizeY);

			// reset
			for (int xi = 0; xi < sizeX; ++xi){
				for (int yi = 0; yi < sizeY; ++yi){
					dfstree[xi][yi] = 0;
				}
			}

			typedef adjacency_list < listS, vecS, undirectedS, no_property, property < edge_weight_t, int > > graph_t;
			typedef graph_traits < graph_t >::vertex_descriptor vertex_descriptor;
			typedef graph_traits < graph_t >::edge_descriptor edge_descriptor;

			std::vector<std::pair<int, int> > edges;
			for (int x = 0; x < sizeX; ++x){
				for (int y = 0; y < sizeY; ++y){
					if (x < sizeX - 1 && maze[x][y] & RIGHT_MASK && maze[x + 1][y] & LEFT_MASK){
						edges.push_back(std::pair<int, int>(y * sizeX + x, y * sizeX + (x + 1)));
					}
					if (y < sizeY - 1 && maze[x][y] & DOWN_MASK && maze[x][y + 1] & UP_MASK){
						edges.push_back(std::pair<int, int>(y * sizeX + x, (y + 1) * sizeX + x));
					}
				}
			}
			std::pair<int, int>* edgeArray = new std::pair<int, int>[edges.size()];
			int* weights = new int[edges.size()];
			for (int i = 0; i < edges.size(); ++i){
				edgeArray[i] = edges[i];
				weights[i] = 1;
			}

			graph_t g(edgeArray, edgeArray + edges.size(), weights, sizeX * sizeY);
			property_map<graph_t, edge_weight_t>::type weightmap = get(edge_weight, g);

			std::vector<vertex_descriptor> p(num_vertices(g));
			std::vector<int> d(num_vertices(g));
			vertex_descriptor s = vertex((startY - 1) * sizeX + (startX - 1), g);

			dijkstra_shortest_paths(g, s, predecessor_map(&p[0]).distance_map(&d[0]));

			int nx = destX - 1;
			int ny = destY - 1;
			while (nx != (startX - 1) || ny != (startY - 1)){
				int px = p[ny * sizeX + nx] % sizeX;
				int py = p[ny * sizeX + nx] / sizeX;

				if (px < nx){
					dfstree[nx][ny] |= LEFT_MASK;
					dfstree[px][py] |= RIGHT_MASK;
				}
				if (px > nx){
					dfstree[nx][ny] |= RIGHT_MASK;
					dfstree[px][py] |= LEFT_MASK;
				}
				if (py < ny){
					dfstree[nx][ny] |= UP_MASK;
					dfstree[px][py] |= DOWN_MASK;
				}
				if (py > ny){
					dfstree[nx][ny] |= DOWN_MASK;
					dfstree[px][py] |= UP_MASK;
				}

				nx = px;
				ny = py;
			}

			delete []edgeArray;
			delete []weights;
		}

		int getWidth(){
			return sizeX;
		}

		int getHeight(){
			return sizeY;
		}

		bool isReachable(int x, int y){
			assert (x >= 1 && x <= sizeX);
			assert (y >= 1 && x <= sizeY);

			return reachable[x - 1][y - 1];
		}

		bool isBorderField(int x, int y){
			if (!reachable[x - 1][y - 1]) return false;

			bool b = false;
			if (x - 1 > 1 && !reachable[x - 2][y - 1]) b = true;
			if (x - 1 < sizeX - 1 && !reachable[x][y - 1]) b = true;
			if (y - 1 > 1 && !reachable[x - 1][y - 2]) b = true;
			if (y - 1 < sizeY - 1 && !reachable[x - 1][y]) b = true;
			return b;
		}

		void getBorderReason(int xReachable, int yReachable, int xUnreachable, int yUnreachable, int* reasonX, int* reasonY, int* reasonLocation){
			assert (isReachable(xReachable, yReachable) && !isReachable(xUnreachable, yUnreachable));
			assert (xReachable == xUnreachable || yReachable == yUnreachable);

			if (xReachable == xUnreachable - 1){
				if (maze[xReachable - 1][yReachable - 1] | RIGHT_MASK == 0){
					*reasonX = xReachable;
					*reasonY = yReachable;
					*reasonLocation = RIGHT_MASK;
				}else if (maze[xUnreachable - 1][yUnreachable - 1] | LEFT_MASK == 0){
					*reasonX = xUnreachable;
					*reasonY = yUnreachable;
					*reasonLocation = LEFT_MASK;
				}else{
					assert(false);
				}
			}
			else if (xUnreachable == xReachable - 1){
				if (maze[xReachable - 1][yReachable - 1] | LEFT_MASK == 0){
					*reasonX = xReachable;
					*reasonY = yReachable;
					*reasonLocation = LEFT_MASK;
				}else if (maze[xUnreachable - 1][yUnreachable - 1] | RIGHT_MASK == 0){
					*reasonX = xUnreachable;
					*reasonY = yUnreachable;
					*reasonLocation = RIGHT_MASK;
				}else{
					assert(false);
				}
			}
			else if (yReachable == yUnreachable - 1){
				if (maze[xReachable - 1][yReachable - 1] | DOWN_MASK == 0){
					*reasonX = xReachable;
					*reasonY = yReachable;
					*reasonLocation = DOWN_MASK;
				}else if (maze[xUnreachable - 1][yUnreachable - 1] | UP_MASK == 0){
					*reasonX = xUnreachable;
					*reasonY = yUnreachable;
					*reasonLocation = UP_MASK;
				}else{
					assert(false);
				}
			}
			else if (yUnreachable == yReachable - 1){
				if (maze[xReachable - 1][yReachable - 1] | UP_MASK == 0){
					*reasonX = xReachable;
					*reasonY = yReachable;
					*reasonLocation = UP_MASK;
				}else if (maze[xUnreachable - 1][yUnreachable - 1] | DOWN_MASK == 0){
					*reasonX = xUnreachable;
					*reasonY = yUnreachable;
					*reasonLocation = DOWN_MASK;
				}else{
					assert(false);
				}
			}
			else{
				assert(false);
			}
		}

		int getUsedEdges(int x, int y){
			assert (x >= 1 && x <= sizeX);
			assert (y >= 1 && x <= sizeY);

			return dfstree[x - 1][y - 1];
		}
	};

	ID edgeToLiteral(ID mazePredicate, int x, int y, int location, bool sign){

		OrdinaryAtom oatom(ID::MAINKIND_ATOM | ID::SUBKIND_ATOM_ORDINARYG);
		oatom.tuple.push_back(mazePredicate);
		oatom.tuple.push_back(ID::termFromInteger(x));
		oatom.tuple.push_back(ID::termFromInteger(y));
		switch (location){
			case Maze::UP_MASK:
				oatom.tuple.push_back(tUid);
				break;
			case Maze::DOWN_MASK:
				oatom.tuple.push_back(tDid);
				break;
			case Maze::LEFT_MASK:
				oatom.tuple.push_back(tLid);
				break;
			case Maze::RIGHT_MASK:
				oatom.tuple.push_back(tRid);
				break;
			default:
				assert(false);
		}
		return NogoodContainer::createLiteral(reg->storeOrdinaryGAtom(oatom).address, sign);
	}
public:
	ReachableAtom():
		PluginAtom("reachable", true)
	{
		addInputPredicate();
		addInputConstant();
		addInputConstant();
		addInputTuple();
		setOutputArity(2);

		prop.monotonicInputPredicates.push_back(0);
	}

	virtual void
	retrieve(const Query& query, Answer& answer) throw (PluginError)
	{
		// should never be called
		assert(false);
	}

	virtual void generalizeNogood(Nogood ng, const std::set<ID>& auxes, ProgramCtx* ctx, NogoodContainerPtr nogoods){

		DBGLOG(DBG, "ReachableAtom::generalizeNogood");

		// find the auxiliary in the nogood
		ID patternID = ID_FAIL;
		BOOST_FOREACH (ID l, ng){
			const OrdinaryAtom& lAtom = ctx->registry()->ogatoms.getByAddress(l.address);

			if (ctx->registry()->ogatoms.getIDByAddress(l.address).isExternalAuxiliary() && ctx->registry()->getIDByAuxiliaryConstantSymbol(lAtom.tuple[0]) == getPredicateID()){
				patternID = l;
				break;
			}
		}
		assert(patternID != ID_FAIL);
		DBGLOG(DBG, "patternID=" << patternID);
		const OrdinaryAtom& pattern = ctx->registry()->ogatoms.getByAddress(patternID.address);

		// for all related auxiliaries
		BOOST_FOREACH (ID auxID, auxes){
			DBGLOG(DBG, "Matching auxID=" << auxID << " (#parameters=" << inputType.size() << ")");
			const OrdinaryAtom& aux = ctx->registry()->ogatoms.getByAddress(auxID.address);

			// find a translation of the tuple of pattern to the tuple of aux
			ID patternMazePred = pattern.tuple[1];
			ID auxMazePred = aux.tuple[1];
			int auxT = aux.tuple.size() < 6 ? -1 : aux.tuple[5];

			// translate the nogood
			Nogood translatedNG;
			BOOST_FOREACH (ID lID, ng){
				const OrdinaryAtom& l = ctx->registry()->ogatoms.getByAddress(lID.address);
				if (lID != patternID){
					OrdinaryAtom t = l;
					if (t.tuple[0] = patternMazePred){
						t.tuple[0] = auxMazePred;
						if (t.tuple.size() == 5){
							t.tuple[4] = ID::termFromInteger(auxT);
						}
						translatedNG.insert(NogoodContainer::createLiteral(ctx->registry()->storeOrdinaryGAtom(t).address, !lID.isNaf()));
					}
				}else{
					OrdinaryAtom t = l;
					t.tuple[1] = auxMazePred;
					if (t.tuple.size() == 6){
						t.tuple[5] = ID::termFromInteger(auxT);
					}
					translatedNG.insert(NogoodContainer::createLiteral(ctx->registry()->storeOrdinaryGAtom(t).address, !lID.isNaf()));
				}
			}

			// store the translated nogood
			DBGLOG(DBG, "Adding generalized nogood " << translatedNG.getStringRepresentation(ctx->registry()) << " (from " << ng.getStringRepresentation(ctx->registry()) << ")");
			nogoods->addNogood(translatedNG);
		}
	}

	virtual void
	retrieve(const Query& query, Answer& answer, ProgramCtx* ctx, NogoodContainerPtr nogoods) throw (PluginError)
	{
		assert(query.input.size() == 3 || query.input.size() == 4);

		reg = getRegistry();

		Term tS(ID::MAINKIND_TERM | ID::SUBKIND_TERM_CONSTANT, "s");
		Term tU(ID::MAINKIND_TERM | ID::SUBKIND_TERM_CONSTANT, "u");
		Term tD(ID::MAINKIND_TERM | ID::SUBKIND_TERM_CONSTANT, "d");
		Term tL(ID::MAINKIND_TERM | ID::SUBKIND_TERM_CONSTANT, "l");
		Term tR(ID::MAINKIND_TERM | ID::SUBKIND_TERM_CONSTANT, "r");
		tSid = reg->storeTerm(tS);
		tUid = reg->storeTerm(tU);
		tDid = reg->storeTerm(tD);
		tLid = reg->storeTerm(tL);
		tRid = reg->storeTerm(tR);

		DBGLOG(DBG, "Constructing maze");
		Maze m(*this, query.interpretation, query.input.size() == 3 ? -1 : query.input[3].address);

		// compute reachable fields
		DBGLOG(DBG, "Computing reachable fields");
		m.dfs(query.input[1].address, query.input[2].address);

		// copy reachable fields to output
		DBGLOG(DBG, "Creating output");
		for (int x = 1; x <= m.getWidth(); ++x){
			for (int y = 1; y <= m.getHeight(); ++y){
				if (m.isReachable(x, y)){
					Tuple out;
					out.push_back(ID::termFromInteger(x));
					out.push_back(ID::termFromInteger(y));
					answer.get().push_back(out); 
				}
			}
		}

		// learning
		if (nogoods){
			if (query.pattern[0].isIntegerTerm() && query.pattern[1].isIntegerTerm()){
				if (m.isReachable(query.pattern[0].address, query.pattern[1].address)){

					// find a path
					m.findpath(query.input[1].address, query.input[2].address, query.pattern[0].address, query.pattern[1].address);

					// store it as reason in the nogood
					Nogood reachableNG;
					for (int x = 1; x <= m.getWidth(); ++x){
						for (int y = 1; y <= m.getHeight(); ++y){
							int ue = m.getUsedEdges(x, y);
							if (ue & Maze::LEFT_MASK) reachableNG.insert(edgeToLiteral(query.input[0], x, y, Maze::LEFT_MASK, true));
							if (ue & Maze::RIGHT_MASK) reachableNG.insert(edgeToLiteral(query.input[0], x, y, Maze::RIGHT_MASK, true));
							if (ue & Maze::UP_MASK) reachableNG.insert(edgeToLiteral(query.input[0], x, y, Maze::UP_MASK, true));
							if (ue & Maze::DOWN_MASK) reachableNG.insert(edgeToLiteral(query.input[0], x, y, Maze::DOWN_MASK, true));
						}
					}

					Tuple t;
					t.push_back(ID::termFromInteger(query.pattern[0].address));
					t.push_back(ID::termFromInteger(query.pattern[1].address));
					reachableNG.insert(NogoodContainer::createLiteral(getOutputAtom(ctx, nogoods, query, t, false)));
					nogoods->addNogood(reachableNG);
//std::cout << "Reachable: " << reachableNG << std::endl;
				}else{
					// find the border between reachable and unreachable fields
					Nogood unreachableNG;
					for (int x = 1; x <= m.getWidth(); ++x){
						for (int y = 1; y <= m.getHeight(); ++y){
							if (m.isBorderField(x, y)){
								int rx, ry, rl;

								// find a reason why this field is a border field and encode it in the nogood
								if (x > 1 && !m.isReachable(x - 1, y)){
									m.getBorderReason(x, y, x - 1, y, &rx, &ry, &rl);
									unreachableNG.insert(edgeToLiteral(query.input[0], rx, ry, rl, false));
								}
								if (x < m.getWidth() && !m.isReachable(x + 1, y)){
									m.getBorderReason(x, y, x + 1, y, &rx, &ry, &rl);
									unreachableNG.insert(edgeToLiteral(query.input[0], rx, ry, rl, false));
								}
								if (y > 1 && !m.isReachable(x, y - 1)){
									m.getBorderReason(x, y, x, y - 1, &rx, &ry, &rl);
									unreachableNG.insert(edgeToLiteral(query.input[0], rx, ry, rl, false));
								}
								if (y < m.getHeight() && !m.isReachable(x, y + 1)){
									m.getBorderReason(x, y, x, y + 1, &rx, &ry, &rl);
									unreachableNG.insert(edgeToLiteral(query.input[0], rx, ry, rl, false));
								}
							}
						}
					}

					Tuple t;
					t.push_back(ID::termFromInteger(query.pattern[0].address));
					t.push_back(ID::termFromInteger(query.pattern[1].address));
					unreachableNG.insert(NogoodContainer::createLiteral(getOutputAtom(ctx, nogoods, query, t, true)));
					nogoods->addNogood(unreachableNG);
//std::cout << "Unreachable: " << unreachableNG << std::endl;
//std::cout << unreachableNG.getStringRepresentation(reg) << std::endl;
//exit(0);
				}
			}

/*
			// for all fields on the border between the reachable and the unreachable area
			Nogood unreachableNG, reachableNG;
			for (int x = 1; x <= m.getWidth(); ++x){
				for (int y = 1; y <= m.getHeight(); ++y){
					if (m.isBorderField(x, y)){
						int rx, ry, rl;

						// find a reason why this field is a border field and encode it in the nogood
						if (x > 1 && !m.isReachable(x - 1, y)){
							m.getBorderReason(x, y, x - 1, y, &rx, &ry, &rl);
							unreachableNG.insert(edgeToLiteral(query.input[0], rx, ry, rl, false));
						}
						if (x < m.getWidth() && !m.isReachable(x + 1, y)){
							m.getBorderReason(x, y, x + 1, y, &rx, &ry, &rl);
							unreachableNG.insert(edgeToLiteral(query.input[0], rx, ry, rl, false));
						}
						if (y > 1 && !m.isReachable(x, y - 1)){
							m.getBorderReason(x, y, x, y - 1, &rx, &ry, &rl);
							unreachableNG.insert(edgeToLiteral(query.input[0], rx, ry, rl, false));
						}
						if (y < m.getHeight() && !m.isReachable(x, y + 1)){
							m.getBorderReason(x, y, x, y + 1, &rx, &ry, &rl);
							unreachableNG.insert(edgeToLiteral(query.input[0], rx, ry, rl, false));
						}
					}
				}
			}

			// for all reachable fields
			for (int x = 1; x <= m.getWidth(); ++x){
				for (int y = 1; y <= m.getHeight(); ++y){
					if (m.isReachable(x, y)){
						int ue = m.getUsedEdges(x, y);
						if (ue & Maze::LEFT_MASK) reachableNG.insert(edgeToLiteral(query.input[0], x, y, Maze::LEFT_MASK, true));
						if (ue & Maze::RIGHT_MASK) reachableNG.insert(edgeToLiteral(query.input[0], x, y, Maze::RIGHT_MASK, true));
						if (ue & Maze::UP_MASK) reachableNG.insert(edgeToLiteral(query.input[0], x, y, Maze::UP_MASK, true));
						if (ue & Maze::DOWN_MASK) reachableNG.insert(edgeToLiteral(query.input[0], x, y, Maze::DOWN_MASK, true));
					}
				}
			}

			for (int x = 1; x <= m.getWidth(); ++x){
				for (int y = 1; y <= m.getHeight(); ++y){
					// store this border information as justification for all unreachable fields
					if (!m.isReachable(x, y)){
						Nogood ng2 = unreachableNG;
						Tuple t;
						t.push_back(ID::termFromInteger(x));
						t.push_back(ID::termFromInteger(y));
						ng2.insert(NogoodContainer::createLiteral(getOutputAtom(ctx, nogoods, query, t, true)));
						nogoods->addNogood(ng2);
					}

					// due to monotonicity the dfs tree is a sufficient justification for all reachable fields
					if (m.isReachable(x, y)){
						Nogood ng2 = reachableNG;
						Tuple t;
						t.push_back(ID::termFromInteger(x));
						t.push_back(ID::termFromInteger(y));
						ng2.insert(NogoodContainer::createLiteral(getOutputAtom(ctx, nogoods, query, t, false)));
						nogoods->addNogood(ng2);
					}
				}
			}
*/
		}
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

