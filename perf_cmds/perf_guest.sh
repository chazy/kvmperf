#!/bin/bash

ssh -p 2222 root@localhost "cat /proc/modules" > /tmp/modules
ssh -p 2222 root@localhost "cat /proc/kallsyms" > /tmp/kallsyms

perf kvm --guest --guestmodules=/tmp/modules --guestkallsyms=/tmp/kallsyms record -a -o perf.data
