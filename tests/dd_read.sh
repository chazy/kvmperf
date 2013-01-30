#!/bin/bash

source common.sh

power_start $i
$TIME dd if=/root/foo bs=1M count=500 of=/dev/null
power_end $i
