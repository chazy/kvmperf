#!/bin/bash

# requires that apache is installed with the gcc manual in place

source common.sh

NR_REQUESTS=100000
ab=/usr/bin/ab
CMD="$ab -n $NR_REQUESTS -c 100 http://localhost/gcc/index.html"

service apache2 start

rm -f time.txt
touch time.txt
for i in `seq 1 $REPTS`; do
	echo -n "."
	power_start $i
	$CMD | tee >(grep 'Requests per second' | awk '{ print $4 }' >> time.txt)
	power_end $i
done
echo ""

service apache2 stop
