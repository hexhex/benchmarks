dlvhex2 --plugindir=../../../core/testsuite/ --silent --filter=edgeline lines.hex stops.hex platforms.hex getedges.hex | sed 's/,edgeline/.edgeline/g' | sed 's/{//' | sed 's/}/./' > vienna-publictransport2.hex 