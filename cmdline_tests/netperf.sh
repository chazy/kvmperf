#!/bin/bash

SRV=$1
REPTS=${2-15}

echo "Measuring netperf performance of $SRV"

echo TCP_STREAM >> $RESULTS
for i in `seq 1 $REPTS`; do
	netperf netperf -H 10.10.1.120 -t TCP_STREAM | tee >(cat > /tmp/netperf_single.txt)
	cat /tmp/netperf_single.txt | tail -n 1 | awk '{ print $5 }' >> $RESULTS
done

echo TCP_RR >> $RESULTS
for i in `seq 1 $REPTS`; do
	netperf netperf -H 10.10.1.120 -t TCP_RR | tee >(cat > /tmp/netperf_single.txt)
	cat /tmp/netperf_single.txt | tail -n 2 | head -n 1 | awk '{ print $6 }' >> $RESULTS
done
