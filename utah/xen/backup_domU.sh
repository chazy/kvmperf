#!/bin/bash

./mountfs_xen.sh
tar -cvzf /srv/vm/domu.tar.gz -C /vm .
./unmountfs_xen.sh
