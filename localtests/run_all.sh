#!/bin/bash

TIMELOG=$(pwd)/localtest.txt

rm -f $TIMELOG
touch $TIMELOG

./pbzip.sh
./fio.sh
./kernbench.sh



cat $TIMELOG
