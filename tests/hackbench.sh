#!/bin/bash

source common.sh

CMD="./hackbench 100 process 500 2>&1 > /dev/null"

$CMD 2>&1 > /dev/null

for i in `seq 1 $REPTS`; do
	$TIME bash -c "$CMD 2>&1"
done

