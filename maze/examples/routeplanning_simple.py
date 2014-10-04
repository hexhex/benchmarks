import dlvhex

def needFuel(visit, edge):
	d = 0
	for x in dlvhex.getInputAtoms():
		if x.isTrue() and x.tuple()[0].value() == visit.value():
			cur = x.tuple()[1]
			prev = getPredec(x.tuple()[2].intValue(), visit)
			if prev != 0:
				d = d + getCost(prev, cur, edge)
	if d > 10:
		dlvhex.output(())

def getPredec(idx, visit):
	for x in dlvhex.getInputAtoms():
		t = x.tuple()
		if x.isTrue() and t[0].value() == visit.value():
			if t[2].intValue() == idx - 1:
				return t[1]
	return 0

def getCost(prev, cur, edge):
	for x in dlvhex.getInputAtoms():
		t = x.tuple()
		if t[0].value() == edge.value():
			if t[1].value() == prev.value() and t[2].value() == cur.value():
				return t[3].intValue()
	return 0

def register():
	dlvhex.addAtom("needFuel", (dlvhex.PREDICATE, dlvhex.PREDICATE), 0)
