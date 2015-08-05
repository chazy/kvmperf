#!/bin/bash

TIMELOG=${TIMELOG-$(pwd)/fio.txt}

source setup.sh

TEST_FIO_REPEAT=${1-3}
FIO_VER="2.1.10"
FIO_DIR="/tmp/fio"
FIO=$FIO_DIR/fio-$FIO_VER/fio
FIO_TAR="$FIO-$FIO_VER.tar.gz"

mkdir -p $FIO_DIR
pushd $FIO_DIR

if [[ -f $FIO ]]; then
	echo "fio is here"
else
	wget http://brick.kernel.dk/snaps/fio-$FIO_VER.tar.gz
	tar xvfz fio-$FIO_VER.tar.gz
	pushd fio-$FIO_VER
	./configure
	make -j 4
	popd
	if [[ -f $FIO ]]; then
		echo "$FIO is ready"
	else
		echo "$FIO is not ready" >&2
		popd
		exit 1
	fi
	sync
fi

_TMPDIR=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
FIO_TEST_DIR=$FIO_DIR/$_TMPDIR


echo "; random write of 128mb of data

[random-write]
rw=randwrite
filename=$FIO_TEST_DIR/${KERNEL_NAME}.tar.xz
direct=1
invalidate=1
iodepth=8
ioengine=sync
" > random-write-test.fio

echo "; random read of 128mb of data

[random-read]
rw=randread
filename=$FIO_TEST_DIR/${KERNEL_NAME}.tar.xz
direct=1
invalidate=1
iodepth=8
ioengine=sync
" > random-read-test.fio

if [[ ! $TEST_FIO_REPEAT == 0 ]]; then
	rm -rf $FIO_TEST_DIR
	mkdir -p $FIO_TEST_DIR

	echo "fio random read (in msec)" >> $TIMELOG
	for i in `seq 1 $TEST_FIO_REPEAT`; do
		cp $KERNEL_XZ $FIO_TEST_DIR
		refresh
		$FIO random-read-test.fio | tee >(grep 'read : io' | awk 'BEGIN { FS = "=" }; {print $5+0}' >> $TIMELOG)
	done
	echo "fio random write (in msec)" >> $TIMELOG
	for i in `seq 1 $TEST_FIO_REPEAT`; do
		cp $KERNEL_XZ $FIO_TEST_DIR
		refresh
		$FIO random-write-test.fio | tee >(grep 'write: io' | awk 'BEGIN { FS = "="}; {print $5+0}' >> $TIMELOG)
	done
	rm -rf $FIO_TEST_DIR
fi

popd
