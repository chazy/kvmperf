#!/bin/bash

TIMELOG=$(pwd)/localtest.txt

rm -f $TIMELOG
touch $TIMELOG

usage() {
	echo "./run_all.sh [pbzip_rpt] [kernbench_rpt] [fio_rpt]" >&2
	echo "" >&2
	echo "Default valus:" >&2
	echo "  pbzip:     3 repts" >&2
	echo "  kernbench: 1 repts" >&2
	echo "  fio:       3 repts" >&2
	exit 0
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
	usage
fi

TEST_PBZIP_REPEAT=${1:-3}
TEST_KERNBENCH_REPEAT=${2:-1}
TEST_FIO_REPEAT=${3:-3}

./pbzip.sh $TEST_PBZIP_REPEAT
./fio.sh $TEST_FIO_REPEAT
./kernbench.sh $TEST_KERNBENCH_REPEAT


cat $TIMELOG
