EXTRA_DIST = \
  run-dlvhex-tests.sh \
  answerset_compare.py

all-local:
	-ln -s $(top_srcdir)/src/pref.encoding
	-ln -s $(top_srcdir)/src/adm.encoding
	-ln -s $(top_srcdir)/src/ideal.encoding
	-ln -s $(top_srcdir)/src/idealset.encoding

all-clean:
	-rm pref.encoding adm.encoding ideal.encoding idealset.encoding

TESTS = run-dlvhex-tests.sh

#  --heuristics=asp:$(top_srcdir)/src/evalheur.asp

TESTS_ENVIRONMENT = \
  TOP_SRCDIR=$(top_srcdir) \
  DLVHEX="$(DLVHEX_BINDIR)/dlvhex2 -s --plugindir=$(top_builddir)/src --solver=genuinegc --flpcheck=ufs --verbose=8" \
  EXAMPLESDIR=$(top_srcdir)/examples \
  TESTS=$(top_srcdir)/examples/tests/arguplugin.test \
  OUTDIR=$(top_srcdir)/examples/tests
