#!/bin/bash

SRV=$1
REPTS=${2-50}

echo "Measuring performance of $SRV"

# requires that apache is installed with the gcc manual in place
NR_REQUESTS=100000
RESULTS=apache.txt
ab=/usr/bin/ab
CMD="$ab -n $NR_REQUESTS -c 100 http://$SRV/gcc/index.html"

service apache2 start

for i in `seq 1 $REPTS`; do
	$CMD | tee >(grep 'Requests per second' | awk '{ print $4 }' >> $RESULTS)
done
