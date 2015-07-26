#!/bin/bash

ip link add link eth1 name kvmtap0 type macvtap mode bridge
ip link set kvmtap0 up
