#!/bin/bash
KERNEL="linux-3.17"
KERNEL_TAR="$KERNEL.tar.gz"
KERNEL_XZ="$KERNEL.tar.xz"
KERNEL_BZ="$KERNEL.tar.xz.bz2"
KB="kernbench"
KB_VER="0.50"
KB_TAR="$KB-$KB_VER.tar.gz"
FIO="fio"
FIO_VER="2.1.10"
FIO_DIR="$FIO-$FIO_VER"
FIO_TAR="$FIO-$FIO_VER.tar.gz"
FIO_TEST_DIR="fio_test"

PBZIP_DIR="pbzip_test"

TEST_PBZIP_REPEAT=3
TEST_KERNBENCH_REPEAT=1
TEST_FIO_REPEAT=3

TIMELOG=$(pwd)/time.txt
TIME="/usr/bin/time --format=%e -o $TIMELOG --append"

refresh() {
	sync && echo 3 > /proc/sys/vm/drop_caches
	sleep 15
}

rm -f $TIMELOG
touch $TIMELOG

apt-get install -y time bc pbzip2 gawk wget

for i in time awk yes date bc pbzip2 wget
do
	iname=`which $i`
	if [[ ! -a $iname ]] ; then
		echo "$i not found in path, please install it; exiting"
		exit
	else
		echo "$i is found: $iname"
	fi
done


if [[ -d $KERNEL ]]; then
	echo "$KERNEL is here"
else
	if [[ -f $KERNEL_TAR ]]; then
		echo "$KERNEL_TAR is here"
	else
		echo "$KERNEL_TAR is not here"
		wget https://www.kernel.org/pub/linux/kernel/v3.x/linux-3.17.tar.gz
		sync
	fi
	echo "Extracing kernel tar..."
	tar xfz $KERNEL_TAR
fi

if [[ -f $KERNEL/$KB ]]; then
	echo "$KB is here"
else
	wget http://ftp.be.debian.org/pub/linux/kernel/people/ck/apps/kernbench/kernbench-0.50.tar.gz
	tar xvfz $KB_TAR
	cp $KB-$KB_VER/$KB $KERNEL
	sync
fi


if [[ -f $KERNEL_XZ ]]; then
	echo "$KERNEL_XZ is here"
else
	echo "$KERNEL_XZ is not here"
	wget https://www.kernel.org/pub/linux/kernel/v3.x/linux-3.17.tar.xz
	sync
fi

if [[ -f $KERNEL_BZ ]]; then
	echo "$KERNEL_BZ is here"
else
	echo "$KERNEL_BZ is not here"
	cp $KERNEL_XZ tmp
	pbzip2 -p2 -m500 $KERNEL_XZ
	mv tmp $KERNEL_XZ
	sync
fi

if [[ -f $FIO_DIR/$FIO ]]; then
	echo "$FIO is here"
else
	wget http://brick.kernel.dk/snaps/fio-2.1.10.tar.gz
	tar xvfz $FIO_TAR
	pushd $FIO_DIR
	./configure
	make
	popd
	if [[ -f $FIO_DIR/$FIO ]]; then
		echo "$FIO is ready"
	else
		echo "$FIO is not ready"
	fi
	sync
fi


echo "; random write of 128mb of data

[random-write]
rw=randwrite
filename=$FIO_TEST_DIR/$KERNEL_XZ
direct=1
invalidate=1
iodepth=8
ioengine=sync
" > random-write-test.fio

echo "; random read of 128mb of data

[random-read]
rw=randread
filename=$FIO_TEST_DIR/$KERNEL_XZ
direct=1
invalidate=1
iodepth=8
ioengine=sync
" > random-read-test.fio

if [[ ! $TEST_PBZIP_REPEAT == 0 ]]; then
	rm -rf $PBZIP_DIR
	mkdir $PBZIP_DIR 

	echo "pbzip2 compress (in sec)" >> $TIMELOG
	for i in `seq 1 $TEST_PBZIP_REPEAT`; do
		cp $KERNEL_XZ $PBZIP_DIR
		refresh
		$TIME pbzip2 -p2 -m500 $PBZIP_DIR/$KERNEL_XZ
		rm $PBZIP_DIR/$KERNEL_BZ
	done 

	echo "pbzip2 decompress (in sec)" >> $TIMELOG
	for i in `seq 1 $TEST_PBZIP_REPEAT`; do
		cp $KERNEL_BZ $PBZIP_DIR
		refresh
		$TIME pbzip2 -d -m500 -p2 $PBZIP_DIR/$KERNEL_BZ
		rm $PBZIP_DIR/$KERNEL_XZ
	done 

	rm -rf $PBZIP_DIR
fi

if [[ ! $TEST_FIO_REPEAT == 0 ]]; then
	rm -rf $FIO_TEST_DIR
	mkdir $FIO_TEST_DIR

	echo "fio random read (in msec)" >> $TIMELOG
	for i in `seq 1 $TEST_FIO_REPEAT`; do
		cp $KERNEL_XZ $FIO_TEST_DIR
		refresh
		./$FIO_DIR/$FIO random-read-test.fio | tee >(grep 'read : io' | awk 'BEGIN { FS = "=" }; {print $5+0}' >> $TIMELOG)
	done
	echo "fio random write (in msec)" >> $TIMELOG
	for i in `seq 1 $TEST_FIO_REPEAT`; do
		cp $KERNEL_XZ $FIO_TEST_DIR
		refresh
		./$FIO_DIR/$FIO random-write-test.fio | tee >(grep 'write: io' | awk 'BEGIN { FS = "="}; {print $5+0}' >> $TIMELOG)
	done
	rm -rf $FIO_TEST_DIR
fi

for i in `seq 1 $TEST_KERNBENCH_REPEAT`; do
	pushd $KERNEL
	echo "kernbench in sec" >> $TIMELOG
	refresh
	./kernbench -M -H -f | tee >(grep 'Elapsed' | awk '{print $3 }' >> $TIMELOG)
	popd
done

cat $TIMELOG

