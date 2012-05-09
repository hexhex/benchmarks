EXTRA_DIST = \
  run-dlvhex-tests.sh \
  answerset_compare.py

TESTS = run-dlvhex-tests.sh

TESTS_ENVIRONMENT = \
  TOP_SRCDIR=$(top_srcdir) \
  DLVHEX="$(DLVHEX_BINDIR)/dlvhex2 -s --plugindir=$(top_builddir)/src " \
  EXAMPLESDIR=$(top_srcdir)/examples \
  TESTDIR=$(top_srcdir)/examples/tests/stringplugintests.test \
  OUTDIR=$(top_srcdir)/examples/tests
