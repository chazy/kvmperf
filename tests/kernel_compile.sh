#!/bin/bash

REPTS_LIM=4

source common.sh

#mkdir ram
#mount -t ramfs none ram
#pushd ram

apt-get -y build-dep linux-generic
apt-get -y install gcc-4.6
mkdir -p ~/bin
ln -s /usr/bin/gcc-4.6 ~/bin/gcc
export PATH=~/bin:$PATH

wget "http://$WEBHOST/$KERNEL_TAR"
if [[ ! $? == 0 ]]; then
	exit 1
fi
echo "Downloaded kernel..."
tar xjf $KERNEL_TAR
echo "Kernel image extracted..."
mkdir $KERNEL
pushd $KERNEL

make vexpress_defconfig
echo "Configured kernel..."

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
