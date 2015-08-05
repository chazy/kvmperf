#!/bin/bash

./isolate_vcpus.sh
PID1=`./qmp-cpus -s /tmp/qmp | head -n 1 | awk '{ print $3 }'`
PID2=`./qmp-cpus -s /tmp/qmp | tail -n 1 | awk '{ print $3 }'`
taskset -p 0x40 $PID1
taskset -p 0x80 $PID2
