#!/bin/bash

source common.sh

URL="http://$WEBHOST/small"

$TIME curl -s $URL > /dev/null
rm $TIMELOG

for i in `seq 1 10`; do
	$TIME bash -c "for j in \`seq 1 100\`; do curl -s $URL > /dev/null; done;"
done
