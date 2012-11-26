#!/bin/bash

source common.sh

CMD="./hackbench $REPTS process 5 2>&1 > /dev/null"

$CMD 2>&1 > /dev/null

for i in `seq 1 $REPTS`; do
	$TIME bash -c "$CMD 2>&1"
done

