#!/bin/bash

source common.sh

URL="http://$WEBHOST/small"

rm $TIMELOG

for i in `seq 1 $REPTS`; do
	echo -n "."
	power_start $i
	$TIME bash -c "for j in \`seq 1 1000\`; do curl -s $URL -o /dev/null; done;"
	power_end $i
done
echo ""
