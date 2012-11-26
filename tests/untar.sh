#!/bin/bash

source common.sh

wget -q "http://$WEBHOST/$KERNEL_TAR"
if [[ ! $? == 0 ]]; then
	exit 1
fi

tar xjf $KERNEL_TAR
rm -rf $KERNEL

for i in `seq 1 10`; do
	rm -rf $KERNEL
	sync
	echo 3 > /proc/sys/vm/drop_caches
	$TIME tar xjf $KERNEL_TAR
done
