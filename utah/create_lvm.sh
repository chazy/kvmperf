#!/bin/bash

source fs-setup.sh

./mkfs_lvm.sh
./mountfs_lvm.sh

mkdir -p /mnt/temp

start=`fdisk -l /vm/guest0.img | tail -n 1 | awk '{print $3}'`

mount -o loop,offset=$(($start * 512)) /vm/guest0.img /mnt/temp

pushd /mnt/vm

cp -a /mnt/temp/* .

popd

./unmountfs_lvm.sh

./reinstall-grub.sh


