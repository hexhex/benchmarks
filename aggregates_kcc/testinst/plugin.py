import dlvhex

def pos(p,x):
	min = 0 
	max = 0
	for a in dlvhex.getInputAtoms():
		if a.tuple()[1] == x:
			if a.isTrue():
				if (a.tuple()[1].value() == "m"):
					min -= 1
					max -= 1
				else:
					min += a.tuple()[1].intValue()
					max += a.tuple()[1].intValue()
			elif not a.isAssigned():
				if (a.tuple()[1].value() == "m"):
					min -= 1
				else:
					max += a.tuple()[1].intValue()
	if (min >= 0):
		dlvhex.output(())
	elif (max >= 0):
		dlvhex.outputUnknown(())

def register():
	prop = dlvhex.ExtSourceProperties()
	prop.setProvidesPartialAnswer(True)
	dlvhex.addAtom("pos", (dlvhex.PREDICATE, dlvhex.CONSTANT), 0, prop)
