#!/bin/bash

source common.sh

for i in `seq 1 $REPTS`; do
	echo -n "."
	./guest-driver vmexit | tee >(grep iterations | sed 's/.*= //g' >> $TIMELOG)
done
echo ""
