#! /bin/bash

# Runs all benchmarks
if [ ! -e $(cd $(dirname $0); pwd) ]; then
	echo "Please prepare requirements file req" >&2
	exit 1
fi

# make sure that we use the correct version of dlvhex
export PATH=$(cd $(dirname $0); pwd)/../../install/bin/:$PATH
export LD_LIBRARY_PATH=$(cd $(dirname $0); pwd)/../../install/libs/
echo "Using PATH: $PATH"
echo "Using LD_LIBRARY_PATH: $LD_LIBRARY_PATH"

# actually start the benchmarks
./multibenchmark.sh "$(cd $(dirname $0); pwd)/dlvhex_allbenchmarksdef" "$(cd $(dirname $0); pwd)/$(date +%y%m%d-%H%M%S)" "$(cd $(dirname $0); pwd)/req"
