#!/bin/bash

TIMELOG=${TIMELOG-$(pwd)/pbzip.txt}

source setup.sh

TEST_PBZIP_REPEAT=${1-3}

PBZIP_DIR="/tmp/pbzip_test"

if [[ $TEST_PBZIP_REPEAT == 0 ]]; then
	exit 0
fi

rm -rf $PBZIP_DIR
mkdir $PBZIP_DIR

echo "pbzip2 compress (in sec)" >> $TIMELOG
for i in `seq 1 $TEST_PBZIP_REPEAT`; do
	cp $KERNEL_XZ $PBZIP_DIR
	refresh
	$TIME pbzip2 -p2 -m500 $PBZIP_DIR/${KERNEL_NAME}.tar.xz
	rm $PBZIP_DIR/${KERNEL_NAME}.tar.xz.bz2
done

echo "pbzip2 decompress (in sec)" >> $TIMELOG
for i in `seq 1 $TEST_PBZIP_REPEAT`; do
	cp $KERNEL_BZ $PBZIP_DIR
	refresh
	$TIME pbzip2 -d -m500 -p2 $PBZIP_DIR/${KERNEL_NAME}.tar.xz.bz2
	rm $PBZIP_DIR/${KERNEL_NAME}.tar.xz
done

rm -rf $PBZIP_DIR
