#!/bin/bash

source common.sh

wget "http://$WEBHOST/$KERNEL_TAR"
tar xjf $KERNEL_TAR
cd $KERNEL

make vexpress_defconfig
make -j 10

for i in `seq 1 10`; do
	make clean
	sync
	echo 3 > /proc/sys/vm/drop_caches
	$TIME -o time.txt --append $KERNEL_BUILD_CMD
done

echo "$result"

