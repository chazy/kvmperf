#!/bin/bash

TIMELOG=${TIMELOG-$(pwd)/hackbench.txt}

source setup.sh

REPTS=${1-4}

for i in `seq 1 $REPTS`; do
	../$TOOLS/hackbench 100 process 500 | tee >(grep 'Time:' | awk '{ print $2 }' >> $TIMELOG)
done
