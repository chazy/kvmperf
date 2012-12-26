#!/bin/bash

source common.sh

URL="http://$WEBHOST/large"

$TIME curl $URL -o /dev/null
rm $TIMELOG

for i in `seq 1 $REPTS`; do
	echo -n "."
	$TIME curl $URL -o /dev/null
done
echo ""
