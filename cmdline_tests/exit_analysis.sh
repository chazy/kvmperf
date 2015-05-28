#!/bin/bash

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo "Usage: $0 <KVM host ip> ./sometest.sh param1 param2 ..." >&2
	exit 1
fi

KVMHOST=$1
shift 1

ssh -oBatchMode=yes -l root $KVMHOST "echo foo > /dev/null"
if [[ "$?" != 0 ]]; then
	echo "KVM Host not recognizing public key, aborting" >&2
	exit 1
fi

ssh -oBatchMode=yes -l root $KVMHOST "echo reset > /sys/kernel/debug/kvm/exit_stats"
$@
ssh -oBatchMode=yes -l root $KVMHOST "cat /sys/kernel/debug/kvm/exit_stats"
