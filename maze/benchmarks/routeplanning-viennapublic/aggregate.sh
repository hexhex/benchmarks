#!/bin/bash

# Call the default aggregation script as follows:
#    aggregate 300 0 0 "3,5,6" "2,4,7,8,9" "" ""
# Columns 3,5,6 will be averaged (contain the total runtime, grounding and solving time)
# Columns 2,4,7,8,9 are added (2: number of instances, 4: timeout, 7,8,9: pathlen, changes, restaurant)
# (Last two parameters say that we don't compute minimum or maximum of any columns)
aggregateresults.sh 300 0 0 "3,5,6" "2,4,7,8,9" "" ""
