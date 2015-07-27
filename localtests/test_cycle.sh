#!/bin/bash

#For such test you need 2 main arguments.
#If it is going to the guest or to the bare metal
#

TEST="all"
GUEST_IP=""
KERNEL="linux-3.17"
KERNEL_TAR="$KERNEL.tar.gz"
KERNEL_XZ="$KERNEL.tar.xz"
KERNEL_BZ="$KERNEL.tar.xz.bz2"
KB="kernbench"
KB_VER="0.50"
KB_TAR="$KB-$KB_VER.tar.gz"
FIO="fio"
FIO_VER="2.1.10"
FIO_DIR="$FIO-$FIO_VER"
FIO_TAR="$FIO-$FIO_VER.tar.gz"
FIO_TEST_DIR="fio_test"

PBZIP_DIR="pbzip_test"


TIMELOG=$(pwd)/time.txt
TIME="/usr/bin/time --format=%e -o $TIMELOG --append"

refresh() {
  sync && echo 3 > /proc/sys/vm/drop_caches
  sleep 15
}

rm -f $TIMELOG
touch $TIMELOG

usage() {
  echo "Usage: $0 [options]\n"
  echo "Options:"
  echo "\t -t | --test <fio|kernbench|pbzip|all>"
  echo "\t -g | --guest <ip>"
}

while :
do
  if [[ $1 == "" ]]; then
    break
  fi
  case "$1" in
    -t | --test )
      TEST="$2"
      shift 2
      ;;
    -g | --guest )
      GUEST_IP="$2"
      shift 2
      ;;
    --) # End of all options
      shift
      break
      ;;
    -*) # Unknown option
      echo "Error: Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

fio() {

  if [[ "$GUEST_IP" == "" ]]; then
    rm -rf $FIO_TEST_DIR
    mkdir $FIO_TEST_DIR
    cp $KERNEL_XZ $FIO_TEST_DIR
    refresh

    echo reset > /sys/kernel/debug/kvm/exit_stats
    ./$FIO_DIR/$FIO random-read-test.fio
    cat /sys/kernel/debug/kvm/exit_stats
    rm -rf $FIO_TEST_DIR
  else
    echo reset > /sys/kernel/debug/kvm/exit_stats
    ssh -oBatchMode=yes -o "StrictHostKeyChecking no" -l root $GUEST_IP "cd ~/kvmperf/localtests/; rm -rf $FIO_TEST_DIR; mkdir $FIO_TEST_DIR; cp $KERNEL_XZ $FIO_TEST_DIR; ./fio-2.1.10/fio random-read-test.fio"
    cat /sys/kernel/debug/kvm/exit_stats
  fi

  cp $KERNEL_XZ $FIO_TEST_DIR
  refresh
  echo reset > /sys/kernel/debug/kvm/exit_stats
  if [[ "$GUEST_IP" == "" ]]; then
    rm -rf $FIO_TEST_DIR
    mkdir $FIO_TEST_DIR
    cp $KERNEL_XZ $FIO_TEST_DIR
    refresh

    echo reset > /sys/kernel/debug/kvm/exit_stats
    ./$FIO_DIR/$FIO random-write-test.fio
    cat /sys/kernel/debug/kvm/exit_stats
    rm -rf $FIO_TEST_DIR
  else
    echo reset > /sys/kernel/debug/kvm/exit_stats
    ssh -oBatchMode=yes -o "StrictHostKeyChecking no" -l root $GUEST_IP "cd ~/kvmperf/localtests/; rm -rf $FIO_TEST_DIR; mkdir $FIO_TEST_DIR; cp $KERNEL_XZ $FIO_TEST_DIR; ./fio-2.1.10/fio random-write-test.fio"
    cat /sys/kernel/debug/kvm/exit_stats
  fi

}

kernbench() {
  if [[ "$GUEST_IP" == "" ]]; then
    pushd $KERNEL
    echo reset > /sys/kernel/debug/kvm/exit_stats
    ./kernbench -M -H -f
    cat /sys/kernel/debug/kvm/exit_stats
    popd
  else
    echo reset > /sys/kernel/debug/kvm/exit_stats
    ssh -oBatchMode=yes -o "StrictHostKeyChecking no" -l root $GUEST_IP "cd ~/kvmperf/localtests/; pushd $KERNEL; ./kernbench -M -H -f; popd;"
    cat /sys/kernel/debug/kvm/exit_stats
  fi
}

pbzip() {

  if [[ "$GUEST_IP" == "" ]]; then
    rm -rf $PBZIP_DIR
    mkdir $PBZIP_DIR
    cp $KERNEL_XZ $PBZIP_DIR
    echo reset > /sys/kernel/debug/kvm/exit_stats
    pbzip2 -p2 -m500 $PBZIP_DIR/$KERNEL_XZ
    cat /sys/kernel/debug/kvm/exit_stats
    rm $PBZIP_DIR/$KERNEL_BZ

    cp $KERNEL_BZ $PBZIP_DIR
    echo reset > /sys/kernel/debug/kvm/exit_stats
    pbzip2 -d -m500 -p2 $PBZIP_DIR/$KERNEL_BZ
    cat /sys/kernel/debug/kvm/exit_stats
    rm $PBZIP_DIR/$KERNEL_XZ
  else
    echo reset > /sys/kernel/debug/kvm/exit_stats
    ssh -oBatchMode=yes -o "StrictHostKeyChecking no" -l root $GUEST_IP "cd ~/kvmperf/localtests/; rm -rf $PBZIP_DIR; mkdir $PBZIP_DIR; cp $KERNEL_XZ $PBZIP_DIR; pbzip2 -p2 -m500 $PBZIP_DIR/$KERNEL_XZ; rm $PBZIP_DIR/$KERNEL_BZ;"
    cat /sys/kernel/debug/kvm/exit_stats
    echo reset > /sys/kernel/debug/kvm/exit_stats
    ssh -oBatchMode=yes -o "StrictHostKeyChecking no" -l root $GUEST_IP "cd ~/kvmperf/localtests/; rm -rf $PBZIP_DIR; mkdir $PBZIP_DIR; cp $KERNEL_XZ $PBZIP_DIR; pbzip2 -d -p2 -m500 $PBZIP_DIR/$KERNEL_XZ; rm $PBZIP_DIR/$KERNEL_BZ;"
    cat /sys/kernel/debug/kvm/exit_stats
  fi

}


case "$TEST" in
  fio )
    fio
    ;;
  all )
    fio
    kernbench
    pbzip
    ;;
  kernbench )
    kernbench
    ;;
  pbzip )
    pbzip
    ;;
esac



