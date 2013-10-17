sed 's/{orderedpath([0-9]*,//g' | sed 's/{//g' | sed 's/)}//g' | sed 's/),orderedpath([0-9]*,/\n/g' | sed 's/\",\"/ ---> /g' | sed 's/,\([0-9]*\),\(.*\)/   [Cost: \1   Line: \2]/g' | sed 's/\"//g'
