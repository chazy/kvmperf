#!/bin/bash

# Make sure mysql-server is installed
service mysql status 2>&1 1>/dev/null
if [[ ! $? == 0 ]]; then
	# MySql not installed - let's install it
	sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password kvm'
	sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password kvm'
	sudo apt-get -y install mysql-server
	echo "manual" >> /etc/init/mysql.override
	service mysql stop
fi

# Make sure sysbench is installed
dpkg -l | grep sysbench
if [[ ! $? == 0 ]]; then
	sudo apt-get -y install sysbench
fi
