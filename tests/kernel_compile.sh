#!/bin/bash

REPTS_LIM=3

source common.sh

#mkdir ram
#mount -t ramfs none ram
#pushd ram

wget "http://$WEBHOST/$KERNEL_TAR"
if [[ ! $? == 0 ]]; then
	exit 1
fi
tar xvjf $KERNEL_TAR
pushd $KERNEL

make vexpress_defconfig
make -j10 zImage

for i in `seq 1 $REPTS`; do
	echo " *** Test $i of $REPTS ***"
	make clean
	$TIME make -j10 zImage
done
popd
mv $KERNEL/$TIMELOG .

#mv $TIMELOG ../.
#popd
