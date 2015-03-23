#!/bin/bash

SERVER=$1
REPTS=4

for i in `seq 1 $REPTS`; do
	memslap --servers $SERVER:11211 --concurrency=100
done
