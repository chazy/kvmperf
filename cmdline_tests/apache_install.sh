#!/bin/bash

which apache2 > /dev/null
if [[ $? != 0 ]]; then
	apt-get install -y apache2
	update-rc.d apache2 disable
fi

which ab > /dev/null
if [[ $? != 0 ]]; then
	sudo apt-get install -y apache2-utils
fi

if [[ ! -d "/var/www/html/gcc" ]]; then
	cd /var/www/html
	wget http://gcc.gnu.org/onlinedocs/gcc-4.4.7/gcc-html.tar.gz
	tar xvf gcc-html.tar.gz
fi
