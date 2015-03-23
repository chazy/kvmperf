#!/bin/bash

dpkg --get-selections | grep '\<memcached\>' > /dev/null 2>&1
if [[ ! $? == 0 ]]; then
	apt-get install -y memcached
	update-rc.d memcached disable
fi

which memslap > /dev/null 2>&1
if [[ ! $? == 0 ]]; then
	apt-get install -y g++ libmemcached10 libmemcached-dev

	MEMCACHED=libmemcached-1.0.18
	cp ../tools/$MEMCACHED.tar.gz /tmp/.
	cd /tmp
	tar xvzf $MEMCACHED.tar.gz

	pushd $MEMCACHED
	./configure
	make -j 8
	make install
	popd
fi

