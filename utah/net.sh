#!/bin/bash

ifconfig eth1 > /dev/null 2>&1
err=$?
if [[ $err != 0 ]]; then
	echo "eth1 not found - are you using the right topology?" >&2
	exit 1
fi

IP=`ifconfig eth1 | grep 'inet addr:' | awk '{ print $2 }' | sed 's/.*://'`
ifconfig eth1 0.0.0.0
brctl addbr br0
brctl addif br0 eth1
ifconfig br0 $IP netmask 255.255.255.0
