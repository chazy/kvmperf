#!/bin/bash

dpkg --get-selections | grep '\<memcached\>' > /dev/null 2>&1
if [[ ! $? == 0 ]]; then
	apt-get install -y memcached
	update-rc.d memcached disable
fi

which memtier_benchmark > /dev/null 2>&1
if [[ $? != 0 ]]; then
	apt-get install -y build-essential autoconf automake libpcre3-dev libevent-dev pkg-config zlib1g-dev
	cd /tmp
	git clone https://github.com/RedisLabs/memtier_benchmark.git
	cd memtier_benchmark
	git checkout aabf9659830ad7a4d126d1fff75ac024dad49d3a
	autoreconf -ivf
	./configure
	make -j 8
	make install
fi
