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
echo "Downloaded kernel..."
tar xjf $KERNEL_TAR
sleep 5
echo "Kernel image extracted..."
pushd $KERNEL

make vexpress_defconfig
echo "Configured kernel..."
make -j10 zImage
echo "Pre-compiled kernel..."

for i in `seq 1 $REPTS`; do
	echo " *** Test $i of $REPTS ***"
	make clean
	power_start $i
	$TIME make -j10 zImage
	power_end $i
done
popd
mv $KERNEL/$TIMELOG .

#mv $TIMELOG ../.
#popd
