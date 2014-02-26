#! /bin/bash

# Runs all benchmarks
if [ ! -e $(dirname $0) ]; then
	echo "Please prepare requirements file req" >&2
	exit 1
fi
./multibenchmark.sh "$(dirname $0)/dlvhex_allbenchmarksdef" "$(dirname $0)/$date" "$(dirname $0)/req"
