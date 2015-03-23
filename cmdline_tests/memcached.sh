#!/bin/bash

SERVER=${1-127.0.0.1}
REPTS=8
RESULTS=memcached.txt

for i in `seq 1 $REPTS`; do
	memslap --servers $SERVER:11211 --concurrency=100 | \
		tee >(grep Took | awk '{ print $2 }' >> $RESULTS)
done
