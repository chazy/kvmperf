#!/bin/bash

# requires that apache is installed with the gcc manual in place
REPTS=4
NR_REQUESTS=100000
RESULTS=apache.txt
ab=/usr/bin/ab
CMD="$ab -n $NR_REQUESTS -c 100 http://localhost/gcc/index.html"

service apache2 start

for i in `seq 1 $REPTS`; do
	$CMD | tee >(grep 'Requests per second' | awk '{ print $4 }' >> $RESULTS)
done
