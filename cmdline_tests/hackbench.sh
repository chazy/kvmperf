#!/bin/bash

for i in `seq 1 4`; do
	../tools_arm64/hackbench 100 process 500
done
