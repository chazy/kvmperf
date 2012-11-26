#!/bin/bash

source common.sh

DD="dd if=/dev/zero bs=1M count=500 conv=fdatasync of=foo"
$DD > /dev/null 2>&1

for i in `seq 1 10`; do
	rm foo
	sync
	echo 3 > /proc/sys/vm/drop_caches
	$TIME $DD > /dev/null 2>&1
done
