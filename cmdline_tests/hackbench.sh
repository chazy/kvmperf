#!/bin/bash

source setup.sh

REPTS=${1-4}
RESULTS=hackbench.txt

for i in `seq 1 $REPTS`; do
	../$TOOLS/hackbench 100 process 500 | tee >(grep 'Time:' | awk '{ print $2 }' >> $RESULTS)
done
