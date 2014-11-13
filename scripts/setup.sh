#! /bin/bash

# This script downloads and setups all existing benchmarks for dlvhex

repo=https://github.com/hexhex
error=0
a1=$(echo $1 | sed 's/^\"//' | sed 's/\"$//')
a2=$(echo $2 | sed 's/^\"//' | sed 's/\"$//')
a3=$(echo $3 | sed 's/^\"//' | sed 's/\"$//')
a4=$(echo $4 | sed 's/^\"//' | sed 's/\"$//')
a5=$(echo $5 | sed 's/^\"//' | sed 's/\"$//')
if [[ $# -lt 1 ]] || [[ $# -gt 5 ]]; then
	error=1
fi
if [[ $# -ge 2 ]] && [[ $a2 != "" ]]; then
	instancesource=$a2
else
	instancesource=http://www.kr.tuwien.ac.at/staff/redl/aspext
fi
if [[ $# -ge 3 ]] && [[ $a3 != "" ]]; then
        configoptions=$a3
fi
if [[ $# -ge 4 ]] && [[ $a4 != "" ]]; then
	buildoptions=$a4
fi
if [[ $# -ge 5 ]] && [[ $a5 != "" ]]; then
	job=$(echo "	Executable = $(basename $0)
			Output = $(basename $0).out
			Error = $(basename $0).error
			Log = $(basename $0).log
			Initialdir = $(cd $(dirname $0); pwd)
			getenv = true
			Notification = never
			$(cat $5)

			Arguments = $1 \\\"$2\\\" \\\"$3\\\" \\\"$4\\\"
			Queue 1
			")
	echo -e "Sending the following job to Condor HT:\n$job"
	echo -e "$job" | condor_submit
	exit 0
fi

if [ $error -eq 1 ]; then
	echo "This script expects the following parameter:" >&2
	echo "  \$1: destination directory" >&2
	echo "  \$2: (optional) web source of instances" >&2
	echo "  \$3: (optional) config options" >&2
	echo "  \$4: (optional) build options" >&2
	echo "  \$5: (optional) condor req file to execute this script using Condor HT" >&2
	exit 1
fi

destination=$1
if [ -e $destination ]; then
	echo "Destination directory already exists, please delete it prior to execution"
	exit 1
fi

mkdir -p $destination
mkdir -p $destination/install
cd $destination

# download dlvhex and all plugins
git clone $repo/core --recursive
git clone $repo/mcsieplugin --recursive
git clone $repo/benchmarks --recursive

# build
echo "Building core"
pushd core
./bootstrap.sh && ./configure --enable-benchmark --prefix=$destination/install $configoptions && make $buildoptions && make install && make check
popd

echo "Building MCSIE"
pushd mcsieplugin
./bootstrap.sh && ./configure --enable-benchmark --prefix=$destination/install PKG_CONFIG_PATH=$destination/install/lib/pkgconfig/ CPPFLAGS=-DNDEBUG $configoptions && make $buildoptions
popd

echo "Building argu"
pushd benchmarks/argu
./bootstrap.sh && ./configure --enable-benchmark --prefix=$destination/install PKG_CONFIG_PATH=$destination/install/lib/pkgconfig/ CPPFLAGS=-DNDEBUG $configoptions && make $buildoptions
popd

echo "Building maze"
pushd benchmarks/maze
./bootstrap.sh && ./configure --enable-benchmark --prefix=$destination/install PKG_CONFIG_PATH=$destination/install/lib/pkgconfig/ CPPFLAGS=-DNDEBUG $configoptions && make $buildoptions
popd

echo "Building sensor"
pushd benchmarks/sensor
./bootstrap.sh && ./configure --enable-benchmark --prefix=$destination/install PKG_CONFIG_PATH=$destination/install/lib/pkgconfig/ CPPFLAGS=-DNDEBUG $configoptions && make $buildoptions
popd

# download instances
echo "Downloading reachability instances"
mkdir $destination/core/benchmarks/reachability/instances
pushd $destination/core/benchmarks/reachability/instances
wget $instancesource/reachability.tar.gz
tar xfv reachability.tar.gz
popd

echo "Downloading mergesort instances"
mkdir $destination/core/benchmarks/mergesort/instances
pushd $destination/core/benchmarks/mergesort/instances
wget $instancesource/mergesort.tar.gz
tar xfv mergesort.tar.gz
popd

echo "Downloading non3col instances"
mkdir $destination/core/benchmarks/non3col/instances
pushd $destination/core/benchmarks/non3col/instances
wget $instancesource/non3col.tar.gz
tar xfv non3col.tar.gz
popd

echo "Downloading houseconfiguration instances"
mkdir $destination/core/benchmarks/house/instances
pushd $destination/core/benchmarks/house/instances
wget $instancesource/house.tar.gz
tar xfv house.tar.gz
popd

echo "Downloading MCSIE instances"
mkdir $destination/mcsieplugin/benchmarks/consistent/instances
pushd $destination/mcsieplugin/benchmarks/consistent/instances
wget $instancesource/mcsie-consistent.tar.gz
tar xfv mcsie-consistent.tar.gz
popd

mkdir $destination/mcsieplugin/benchmarks/inconsistent/instances
pushd $destination/mcsieplugin/benchmarks/inconsistent/instances
wget $instancesource/mcsie-inconsistent.tar.gz
tar xfv mcsie-inconsistent.tar.gz
popd

mkdir $destination/mcsieplugin/benchmarks/wjflp/instances
pushd $destination/mcsieplugin/benchmarks/wjflp/instances
wget $instancesource/mcsie-consistent.tar.gz
tar xfv mcsie-consistent.tar.gz
wget $instancesource/mcsie-inconsistent.tar.gz
tar xfv mcsie-inconsistent.tar.gz
popd

echo "Downloading argu instances"
mkdir $destination/benchmarks/argu/benchmarks/ufs/instances
pushd $destination/benchmarks/argu/benchmarks/ufs/instances
wget $instancesource/argu.tar.gz
tar xfv argu.tar.gz
popd

echo "Downloading argu instances"
mkdir $destination/benchmarks/argu/benchmarks/liberalsafety/instances
pushd $destination/benchmarks/argu/benchmarks/liberalsafety/instances
wget $instancesource/argu.tar.gz
tar xfv argu.tar.gz
popd

echo "Downloading argu instances"
mkdir $destination/benchmarks/argu/benchmarks/wjflp/instances
pushd $destination/benchmarks/argu/benchmarks/wjflp/instances
wget $instancesource/arguwjflp.tar.gz
tar xfv arguwjflp.tar.gz
popd

echo "Downloading routeplanning instances"
mkdir $destination/benchmarks/maze/benchmarks/routeplanning-viennapublic/instances
pushd $destination/benchmarks/maze/benchmarks/routeplanning-viennapublic/instances
wget $instancesource/routeplanning-singlefull.tar.gz
tar xfv routeplanning-singlefull.tar.gz 
popd

mkdir $destination/benchmarks/maze/benchmarks/routeplanning-viennapublic/instances_only_sub
pushd $destination/benchmarks/maze/benchmarks/routeplanning-viennapublic/instances_only_sub
wget $instancesource/routeplanning-singlesub.tar.gz
tar xfv routeplanning-singlesub.tar.gz
popd

mkdir $destination/benchmarks/maze/benchmarks/routeplanning-viennapublic/instances_only_subtram
pushd $destination/benchmarks/maze/benchmarks/routeplanning-viennapublic/instances_only_subtram
wget $instancesource/routeplanning-singlesubtram.tar.gz
tar xfv routeplanning-singlesubtram.tar.gz
popd

mkdir $destination/benchmarks/maze/benchmarks/pairrouteplanning-viennapublic/instances
pushd $destination/benchmarks/maze/benchmarks/pairrouteplanning-viennapublic/instances
wget $instancesource/routeplanning-pairfull.tar.gz
tar xfv routeplanning-pairfull.tar.gz
popd

mkdir $destination/benchmarks/maze/benchmarks/pairrouteplanning-viennapublic/instances
pushd $destination/benchmarks/maze/benchmarks/pairrouteplanning-viennapublic/instances
wget $instancesource/routeplanning-pairsub.tar.gz
tar xfv routeplanning-pairsub.tar.gz
popd

mkdir $destination/benchmarks/maze/benchmarks/pairrouteplanning-viennapublic/instances
pushd $destination/benchmarks/maze/benchmarks/pairrouteplanning-viennapublic/instances
wget $instancesource/routeplanning-pairsubtram.tar.gz
tar xfv routeplanning-pairsubtram.tar.gz
popd

mkdir $destination/benchmarks/maze/benchmarks/pairrouteplanningnonrec-viennapublic/instances
pushd $destination/benchmarks/maze/benchmarks/pairrouteplanningnonrec-viennapublic/instances
wget $instancesource/routeplanning-pairfull.tar.gz
tar xfv routeplanning-pairfull.tar.gz
popd

mkdir $destination/benchmarks/maze/benchmarks/pairrouteplanningnonrec-viennapublic/instances
pushd $destination/benchmarks/maze/benchmarks/pairrouteplanningnonrec-viennapublic/instances
wget $instancesource/routeplanning-pairsub.tar.gz
tar xfv routeplanning-pairsub.tar.gz
popd

mkdir $destination/benchmarks/maze/benchmarks/pairrouteplanningnonrec-viennapublic/instances
pushd $destination/benchmarks/maze/benchmarks/pairrouteplanningnonrec-viennapublic/instances
wget $instancesource/routeplanning-pairsubtram.tar.gz
tar xfv routeplanning-pairsubtram.tar.gz
popd

echo "Downloading planning instances"
mkdir $destination/benchmarks/sensor/benchmarks/instances
pushd $destination/benchmarks/sensor/benchmarks/instances 
wget $instancesource/planning.tar.gz
tar xfv planning.tar.gz
popd

echo "Adopting benchmark definition script"
pushd $destination/benchmarks/scripts
prefix=$destination
templatecmd=$(cat dlvhex_allbenchmarksdef_template | cat dlvhex_allbenchmarksdef_template | sed 's/^/echo \"/;s/$/\"/')
eval "$templatecmd" > dlvhex_allbenchmarksdef
popd
