#!/bin/bash

if [[ ! -d "/var/www" ]]; then
	apt-get install -y apache2
	update-rc.d apache2 remove
fi
