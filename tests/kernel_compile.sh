#!/bin/bash

source common.sh

wget -q "http://$WEBHOST/$KERNEL_TAR"
if [[ ! $? == 0 ]]; then
	exit 1
fi
tar xjf $KERNEL_TAR
pushd $KERNEL

make vexpress_defconfig
make -j $REPTS

for i in `seq 1 $REPTS`; do
	make clean
	#sync
	#echo 3 > /proc/sys/vm/drop_caches
	$TIME $KERNEL_BUILD_CMD
done
popd
mv $KERNEL/$TIMELOG .
