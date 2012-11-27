#!/bin/bash

source common.sh

URL="http://$WEBHOST/small"

$TIME curl -s $URL > /dev/null
rm $TIMELOG

for i in `seq 1 $REPTS`; do
	$TIME bash -c "for j in \`seq 1 1000\`; do curl -s $URL > /dev/null; done;"
done
