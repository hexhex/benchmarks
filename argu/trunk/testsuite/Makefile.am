EXTRA_DIST = \
  run-dlvhex-tests.sh \
  answerset_compare.py

TESTS = run-dlvhex-tests.sh

TESTS_ENVIRONMENT = \
  TOP_SRCDIR=$(top_srcdir) \
  DLVHEX="$(DLVHEX_BINDIR)/dlvhex2 -s --plugindir=$(top_builddir)/src --solver=genuinegc --flpcheck=explicit --verbose=8" \
  EXAMPLESDIR=$(top_srcdir)/examples \
  TESTS=$(top_srcdir)/examples/tests/arguplugin.test \
  OUTDIR=$(top_srcdir)/examples/tests
