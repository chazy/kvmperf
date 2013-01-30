#!/bin/bash

source common.sh

chmod a+x qemu-system-x86_64

for i in `seq 1 $REPTS`; do
	echo -n "."
	./qemu-system-x86_64 -smp 1 -device testdev,chardev=testlog \
		-chardev file,id=testlog,path=msr.out \
		-serial stdio \
		-kernel vmexit.flat | tee >(grep vmcall | awk '{ print $2 }' >> $TIMELOG)
done
echo ""
