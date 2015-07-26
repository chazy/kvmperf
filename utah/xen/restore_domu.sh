#!/bin/bash

./mountfs_xen.sh
tar -xvzf domu.tar.gz -C /vm
./unmountfs_xen.sh
