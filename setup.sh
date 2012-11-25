#!/bin/bash

HOST="arndale"
GUEST1="guest1"

echo -n "What's the DNS/IP of the host? [$HOST]:"
_HOST=`read`
if [[ -n "$_HOST" ]]; then
	HOST="_HOST"
fi

echo -n "What's the DNS/IP of the guest? [$GUEST1]:"
_GUEST1=`read`
if [[ -n "$_GUEST1" ]]; then
	GUEST="_GUEST"
fi

echo ""

START_VM_COMMAND="cd /root && ./run-ubuntu.sh"



