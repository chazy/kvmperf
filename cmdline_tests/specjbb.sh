#!/bin/bash

JDK=/usr/local/jdk7-server-release-1502
JAVA=$JDK/jre/bin/java

if [[ ! -e $JDK ]]; then
	echo "java not installed - run jdk_install.sh ?" >&2
	exit 1
fi

SPECJVM=/usr/local/SPECjvm2008
if [[ ! -d $SPECJVM ]]; then
	if [[ ! -e /tmp/SPECjvm2008.tar.gz ]]; then
		wget -P /tmp http://www.cs.columbia.edu/~cdall/SPECjvm2008.tar.gz
	fi
	tar -C /usr/local -xf /tmp/SPECjvm2008.tar.gz
fi

cd $SPECJVM
$JAVA -Xmx10g -jar SPECjvm2008.jar $@
