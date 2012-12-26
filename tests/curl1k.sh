#!/bin/bash

source common.sh

URL="http://$WEBHOST/small"

$TIME curl $URL -o /dev/null
rm $TIMELOG

for i in `seq 1 $REPTS`; do
	echo -n "."
	$TIME bash -c "for j in \`seq 1 1000\`; do curl -s $URL -o /dev/null; done;"
done
echo ""
