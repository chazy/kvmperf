#!/bin/bash

brctl addbr xenbr0
ifconfig xenbr0 10.0.0.1 up

echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -A FORWARD --in-interface xenbr0 -j ACCEPT
iptables --table nat -A POSTROUTING --out-interface eth0 -j MASQUERADE
