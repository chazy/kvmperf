#!/bin/bash

BD=/dev/vg_domU1/domU1

dd if=mbr_domu.bin of=/dev/vg_domU1/domU1 bs=512 count=2

mkdir -p /vm
mount $BD /vm
tar -xvzf domu.tar.gz -C /vm
umount /vm
