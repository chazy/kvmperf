#!/bin/bash

source common.sh

URL="http://$WEBHOST/large"

rm $TIMELOG

for i in `seq 1 $REPTS`; do
	echo -n "."
	power_start $i
	$TIME curl $URL -o /dev/null
	power_end $i
done
echo ""
