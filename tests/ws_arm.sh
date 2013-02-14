#!/bin/bash

source common.sh

for i in `seq 1 $REPTS`; do
	echo -n "."
	perf stat -e cycles:hk -a bash -c "./guest-driver vmexit | tee >(grep iterations | sed 's/.*= //g' >> $TIMELOG)"
done
echo ""
