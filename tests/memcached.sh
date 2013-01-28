#!/bin/bash

source common.sh

CMD="memslap --servers 127.0.0.1:11211 --concurrency=100"
$CMD

for i in `seq 1 $REPTS`; do
	echo " *** Test $i of $REPTS ***"
	$TIME $CMD
done
