Introduction
============
This is a hacked together test suite of a number benchmarks I use to run
workloads on KVM/ARM and x86 platforms to evaluate the relative performance.

How to use
==========
This is what you need:
 - An ARM board that can run VMs (like an A15 of some sort)
 - The ARM board must be running a KVM-enabled kernel
 - The ARM board must be accessible by ssh using public key authentication to
   `root@<board-ip>` without providing a password
 - The ARM board must have a script in root's home folder named `run-ubuntu.sh`,
   which runs a VM using either QEMU or kvmtool.  Sample script for
   `run-guest.sh` is provided here - `run-ubuntu.sh` is just a wrapper that sets
   the name to ubuntu.  The script will assume a file named ubuntu.img
   containing a file system image.
 - The guest must use bridged networking and must also accept ssh connections
   using public key authentication just like the board itself:
   `ssh root@<guest-ip>`

TODO: Describe required support for x86
TODO: Describe how to use the power test

Then, to run a test, you simply do:
<code>
	./run-all.sh --help
</code>
...and follow the instructions


Experiments Logbook
===================

To carry out the full test suite, we need:

- SMP numbers host/guest
- UP number host/guest
- ARM no vgic/timers guest SMP/UP
- LMBENCH ARM/x86
- Power Numbers



Laptop Notes
------------
1. Boot host with "maxcpus=2 mem=1536M" on the kernel command line
2. Get non-graphics tty (ctrl+alt+f6)
3. shutdown not-needed services
    1. service lightdm stop
    2. service network-manager stop
    3. service avahi-daemon stop
2. for i in `seq 0 1`; do cpufreq-set -c $i -g performance; done;' 
3. ./run-all.sh --host-only
4. TODO: LMBENCH
5. Boot host with "maxcpus=2 mem=2048M" on the kernel command line
6. Get non-graphics tty (ctrl+alt+f6)
7. shutdown not-needed services
    1. service lightdm stop
    2. service network-manager stop
    3. service avahi-daemon stop
8. sudo bash -c 'for i in `seq 0 1`; do cpufreq-set -c $i -g performance; done;' 
9. ./run-all.sh --guest-only


3.10 Measurement Notes
----------------------
Arndale host source:
git://github.com/columbia/linux-kvm-arm.git v3.10-arndale-measue
5cf2e8efe14e8aba05432e02edce59c252e3500c

git://github.com/columbia/linux-kvm-arm.git v3.10-vexpress-measure
94af25f43d7864caa3cda269ea63885c984395a6
