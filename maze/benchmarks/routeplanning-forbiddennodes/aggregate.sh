#!/bin/bash

# Call the default aggregation script as follows:
#    aggregateresults.sh 300 0 0 "3,5,6,7,8,9,10,11,13,14,15,16,17,18,19,21,22,23,24,25,26" "2,4,12,20" "" ""
# Columns 3,5,6,7,8,9,10,11,13,14,15,16,17,18,19,21,22,23,24,25,26 will be averaged (3,11,19 contain the total runtime, 5,13,22 grounding and 6,14,23 solving time)
# Columns 2,4,12,20 are added (2: number of instances, 4,12,20: timeouts)
# (Last two parameters say that we don't compute minimum or maximum of any columns)
aggregateresults.sh 300 0 0 "3,5,6,7,8,9,10,11,13,14,15,16,17,18,19,21,22,23,24,25,26" "2,4,12,20" "" ""
