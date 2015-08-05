#!/bin/bash

if [[ ! -d "/var/www" ]]; then
	sudo apt-get install -y apache2
	sudo update-rc.d apache2 disable
fi
