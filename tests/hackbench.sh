#!/bin/bash

source common.sh

CMD="./hackbench 100 process 500"

$CMD

for i in `seq 1 $REPTS`; do
	echo -n "."
	power_start $i
	$TIME bash -c "$CMD"
	power_end $i
done
echo ""

