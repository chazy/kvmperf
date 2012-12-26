#!/bin/bash

source common.sh

CMD="./hackbench 100 process 500"

$CMD

for i in `seq 1 $REPTS`; do
	echo -n "."
	$TIME bash -c "$CMD"
done
echo ""

