#!/bin/bash

# First, install distro package and dependencies
apt-get install -y openjdk-7-jre-headless


# Then install the specific release knowen to work with SPEC JVM 2008
if [[ -e /usr/local/jdk7-server-release-1502 ]]; then
	echo "/usr/local/jdk7-server-release-1502 already exists, exiting" >&2
	exit 1
fi

cd /tmp
wget http://openjdk.linaro.org/releases/jdk7-server-release-1502.tar.xz

cd /usr/local
tar xf /tmp/jdk7-server-release-1502.tar.xz
