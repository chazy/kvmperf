#!/bin/bash

source common.sh

$TIME dd if=/root/foo bs=1M count=500 of=/dev/null
