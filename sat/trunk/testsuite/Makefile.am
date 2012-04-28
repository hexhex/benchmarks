EXTRA_DIST = \
  run-dlvhex-tests.sh

TESTS = run-dlvhex-tests.sh

TESTS_ENVIRONMENT = \
  TOP_SRCDIR=$(top_srcdir) \
  DLVHEX="$(DLVHEX_BINDIR)/dlvhex2 -s --plugindir=$(top_builddir)/src " \
  EXAMPLESDIR=$(top_srcdir)/examples \
  TESTS="$(top_srcdir)/examples/tests/sattests.test $(top_srcdir)/examples/tests/unsattests.test" \
  OUTDIR=$(top_srcdir)/examples/tests
