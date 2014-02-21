mydir="$(dirname $0)"
$5/runconfigs.sh "dlvhex2 --plugindir=$mydir/../../src --argumode=idealset INST CONF" "--solver=genuinegc;--solver=genuineii" $3 $4
