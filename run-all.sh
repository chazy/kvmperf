#!/bin/bash

source setup.sh

HOST_DIR=""
GUEST_DIR=""
GUEST_ALIVE=0
APACHE_STARTED=""
MYSQL_STARTED=""

echo "" > /tmp/kvmperf.log


trap 'early_exit; exit;' SIGINT SIGQUIT

early_exit()
{
	echo ""

	if [[ -n "$HOST_DIR" ]]; then
		echo -n "Removing temporary directory on the host..."
		$SSSH root@$HOST "umount $HOST_DIR/ram"
		ssh root@$HOST "rm -rf $HOST_DIR"
		echo "done"
	fi
	if [[ -n "$GUEST_DIR" ]]; then
		echo -n "Removing temporary directory on the guest"
		$SSSH root@$GUEST1 "umount $GUEST_DIR/ram"
		ssh root@$GUEST1 "rm -rf $GUEST_DIR"
		echo "done"
	fi
	if [[ -n "$APACHE_STARTED" ]]; then
		echo -n "Stopping service apache2 on $APACHE_STARTED..."
		$SSH 2>/dev/null 1>/dev/null root@$APACHE_STARTED "service apache2 stop"
		echo "done"
	fi
	if [[ -n "$MYSQL_STARTED" ]]; then
		echo -n "Stopping service mysql on $MYSQL_STARTED..."
		$SSH 2>/dev/null 1>/dev/null root@$MYSQL_STARTED "service mysql stop"
		echo "done"
	fi
	if [[ $GUEST_ALIVE == 1 ]]; then
		echo -n "Shutting down VM..."
		shutdown_guest
		echo "done"
	fi
	echo "Exiting!"
	exit 1
}

function start_guest()
{
	GUEST_ALIVE=1
	sleep 1
	echo "Starting guest with command: $START_VM_COMMAND" | tee -a $LOGFILE
	ssh -f root@$HOST 2>&1 >>$LOGFILE "$START_VM_COMMAND"
	if [[ ! $? == 0 ]]; then
		echo "Error starting guest - check logfile!" >&2
		return 1
	fi
	return 0
}

function shutdown_guest()
{
	GUEST_ALIVE=0
	echo "Shutting down guest" 2>&1 | tee -a $LOGFILE
	ssh root@$GUEST1 "halt -p"
	sleep 20
	ssh root@$HOST "$SHUTDOWN_VM_COMMAND" 2>&1 | tee -a $LOGFILE
	sleep 1
	if [[ -n "$VM_CONSOLE" ]]; then
		$SCP root@$HOST:$VM_CONSOLE /tmp/.
		echo "VM Console:" >> $LOGFILE
		cat /tmp/$(basename $VM_CONSOLE) >> $LOGFILE
	fi
}

function wait_for_remote()
{
	remote=$1
	echo "Waiting for $remote to become alive" >> $LOGFILE
	wait=1
	timeout=120
	while [[ $wait == 1 && $timeout -gt 0 ]]; do
		ping -q -c 1 $remote > /dev/null
		wait=$?
		sleep 1
		timeout=$(($timeout - 1))
	done
	if [[ $timeout == 0 ]]; then
		return 1
	else
		sleep 3
		return 0
	fi
}

function set_remote_dir()
{
	remote_dir="$1"
	if [[ $GUEST_ALIVE == 0 ]]; then
		HOST_DIR="$remote_dir"
	else
		GUEST_DIR="$remote_dir"
	fi
}

#
# Run with common_test <unit under test> <dns/ip of machine> [<tool> ...]
#
function common_test()
{
	uut="$1"	# unit under test
	remote="$2"	# dns/ip for machine to test
	shift 2

	cmdname="$uut.sh"
	rand=$RANDOM
	remote_dir=/tmp/${uut}_${rand}
	set_remote_dir "$remote_dir"

	# Create remote directory, upload common scripts and tools
	echo "Uploading common scripts and tools" | tee -a $LOGFILE
	ssh root@$remote "mkdir $remote_dir"
	$SCP ".localconf" root@$remote:$remote_dir/.
	$SCP "tests/common.sh" root@$remote:$remote_dir/.
	$SCP "tests/$cmdname" root@$remote:$remote_dir/.
	while [[ -n $1 ]]; do
		file=`basename $1`
		scp -q "$TOOLS/$file" root@$remote:$remote_dir/.
		shift 1
	done

	# Actually run the test command
	rm -f /tmp/time.txt
	echo "Going to actually run the test" | tee -a $LOGFILE
	remote_cmd=""\
"chmod a+x $remote_dir/$cmdname && "\
"cd $remote_dir && "\
"./$cmdname"
	$SSH -t root@$remote "$remote_cmd" 2>&1 | tee -a $LOGFILE
	if [[ $? == 255 ]]; then
		early_exit
	fi

	# Get time stats
	echo "Downloading time stats" | tee -a $LOGFILE
	$SCP root@$remote:$remote_dir/time.txt /tmp/time.txt
	tr '\n' '\t' < /tmp/time.txt | tee -a $LOGFILE
	echo "" | tee -a $LOGFILE

	# Output in nice format as well
	echo -en " $uut (${remote})\t" >> $OUTFILE
	cat /tmp/time.txt | tr '\n' '\t' | tr '\r' ' ' >> $OUTFILE
	echo "" >> $OUTFILE

	# Clean up
	echo "Cleaning up" | tee -a $LOGFILE
	ssh root@$remote "umount $remote_dir/ram 2>/dev/null" | tee -a $LOGFILE
	ssh root@$remote "rm -rf $remote_dir" | tee -a $LOGFILE
	set_remote_dir ""
}

###########################################################################
# Here follows hackbench results
#

function hackbench_test()
{
	common_test "$1" "$2" hackbench
}

function kernel_compile_test()
{
	common_test "$1" "$2"
}

function untar_test()
{
	common_test "$1" "$2"
}

function curl1k_test()
{
	common_test "$1" "$2"
}

function curl1g_test()
{
	common_test "$1" "$2"
}

function dd_write_test()
{
	common_test "$1" "$2"
}

function dd_read_test()
{
	uut="$1"	# unit under test
	remote="$2"	# dns/ip for machine to test

	ORIG_OUTFILE="$OUTFILE"
	OUTFILE=/tmp/.results

	echo -en " $uut (${remote})\t" >> $ORIG_OUTFILE

	common_test "$1_prepare" "$2"

	if [[ $GUEST_ALIVE == 0 ]]; then
		for i in `seq 1 $REPTS`; do
			rm "$OUTFILE"
			common_test "$1" "$2"
			echo "================= reading content from $OUTFILE ============="
			cat "$OUTFILE"
			cat "$OUTFILE" | awk '{ print $3 }' | tr '\n' '\t' >> "$ORIG_OUTFILE"

			ssh root@$remote "sync"
			ssh root@$remote " sudo bash -c 'echo 3 > /proc/sys/vm/drop_caches'"
		done
	else
		# VM must be rebooted between each run here
		for i in `seq 1 $REPTS`; do
			shutdown_guest

			rm "$OUTFILE"
			ssh root@$remote "sync"
			ssh root@$remote " sudo bash -c 'echo 3 > /proc/sys/vm/drop_caches'"

			start_guest
			if [[ ! $? == 0 ]]; then
				echo "Error starting guest - check logfile!" >&2
				return 1
			fi

			wait_for_remote $GUEST1
			if [[ ! $? == 0 ]]; then
				echo "Guest didn't respond in a timely manner - check logfile!" >&2
				return 1
			fi

			common_test "$1" "$2"
			echo "================= reading content from $OUTFILE ============="
			cat "$OUTFILE"
			cat "$OUTFILE" | awk '{ print $3 }' | tr '\n' '\t' >> "$ORIG_OUTFILE"
		done
	fi

	ssh root@$remote "rm -f /root/foo"

	OUTFILE="$ORIG_OUTFILE"
	echo "" >> $OUTFILE
}

function dd_rw_test()
{
	common_test "$1" "$2"
}

function fake_test()
{
	common_test "$1" "$2"
}

function ws_arm_test()
{
	common_test "$1" "$2" guest-driver vmexit-guest
}

function ws_x86_test()
{
	common_test "$1" "$2" qemu-system-x86_64 vmexit.flat en-us common modifiers \
		tools_x86/*.bin tools_x86/*.rom
}

source tests/apache.sh
source tests/mysql.sh

##########################################################################
# Test Harness
#

TESTS="hackbench untar curl1k curl1g apache mysql dd_write dd_read dd_rw kernel_compile ws_arm ws_x86"
GUEST_ONLY_TESTS=""
HOST_ONLY_TESTS="ws_arm ws_x86"
ARM_ONLY_TESTS="ws_arm"
x86_ONLY_TESTS="ws_x86"

fn_exists()
{
    type $1 2>/dev/null | grep -q 'is a function' 1> /dev/null 2>&1
}

function belongsto()
{
	ARR=( $2 )
	for _X in ${ARR[@]}; do
		if [[ "$_X" == "$1" ]]; then
			return 1
		fi
	done
	return 0
}

is_guest_only()
{
	belongsto $1 "$GUEST_ONLY_TESTS"
	return $?
}

is_host_only()
{
	belongsto $1 "$HOST_ONLY_TESTS"
	return $?
}

is_arm_only()
{
	belongsto $1 "$ARM_ONLY_TESTS"
	return $?
}

is_x86_only()
{
	belongsto $1 "$x86_ONLY_TESTS"
	return $?
}

function run_test
{
	TEST="$1"

	RUN_IN_GUEST=1
	RUN_ON_HOST=1

	is_arm_only $TEST
	ARM_ONLY=$?
	is_x86_only $TEST
	X86_ONLY=$?
	if [[ "$ARCH" == "x86" && $ARM_ONLY == 1 ]]; then
		echo "Skipping ARM-only test: $TEST"
		return 1
	elif [[ "$ARCH" == "arm" && $X86_ONLY == 1 ]]; then
		echo "Skipping x86-only test: $TEST"
		return 1
	fi


	is_host_only "$TEST"
	if [[ $? == 1 ]]; then
		RUN_IN_GUEST=0
	fi

	is_guest_only "$TEST"
	if [[ $? == 1 ]]; then
		RUN_ON_HOST=0
	fi

	if ! fn_exists "${TEST}_test"; then
		echo "Test function ${TEST}_test not defined!"
		return 1
	fi

	echo "($TEST):" | tee -a $LOGFILE

	# Run test on native side (unless a guest-only test)
	if [[ $RUN_ON_HOST == 1 ]]; then
		echo -en "native:\t" | tee -a $LOGFILE
		eval "${TEST}_test $TEST $HOST"
	fi

	if [[ $RUN_IN_GUEST == 1 ]]; then
		start_guest
		
		if [[ ! $? == 0 ]]; then
			echo "Error starting guest - check logfile!" >&2
			return 1
		fi

		wait_for_remote $GUEST1
		if [[ ! $? == 0 ]]; then
			echo "Guest didn't respond in a timely manner - check logfile!" >&2
			return 1
		fi
		echo -en "   kvm:\t"
		eval "${TEST}_test $TEST $GUEST1"

		shutdown_guest $GUEST1
	fi

	return 0
}

usage() {
	U=""
	if [[ -n "$1" ]]; then
		U="${U}$1\n\n"
	fi
	U="${U}Usage: $0 [options] [test-names] \n\n"
	U="${U}Options:\n"
	U="$U    --host-only:       Only run test(s) on host\n"
	U="$U    --guest-only:      Only run test(s) on VM guests\n"
	U="$U    -h | --help:       Show this message\n"
	U="$U\n"
	U="${U}Available tests are:\n"
	U="$U    $TESTS\n"

	echo -e "$U" >&2
}


HONLY=0
GONLY=0

while :
do
	case "$1" in
	  --host-only)
		if [[ $GONLY == 1 ]]; then
			usage "error: $1 conflicts with --guest-only"
			exit 1
		fi
		HONLY=1
		shift 1
		;;
	  --guest-only)
		if [[ $HONLY == 1 ]]; then
			usage "error: $1 conflicts with --host-only"
			exit 1
		fi
		GONLY=1
		shift 1
		;;
	  -h | --help)
		usage
		exit 0
		;;
	  --) # End of all options
		shift
		break
		;;
	  -*) # Unknown option
		usage "Error: Unknown option: $1"
		exit 1
		;;
	  *)
		if [[ -n "$1" ]]; then
			TESTS="$1"
		fi
		shift 1
		break
		;;
	esac
done

#TODO: Don't allow a host-only test to become a guest-only test... eh.
if [[ $HONLY == 1 ]]; then
	HOST_ONLY_TESTS="$TESTS"
elif [[ $GONLY == 1 ]]; then
	GUEST_ONLY_TESTS="$TESTS"
fi

echo -e "\n" >> $OUTFILE
echo -n "Performing KVM benchmarks (" >> $OUTFILE
date | tr '\n' ')' >> $OUTFILE
echo >> $OUTFILE

i=1
TESTS=( $TESTS )
total=$(( ${#TESTS[@]} + ${#HOST_TESTS[@]} ))
for TEST in ${TESTS[@]}; do
	echo "============================================" | tee -a $LOGFILE
	echo -n "Test $i of $total " | tee -a $LOGFILE

	run_test "$TEST"

	echo "============================================" | tee -a $LOGFILE
	echo -e "\n\n" | tee -a $LOGFILE
	i=$(($i+1))
done

echo "Done. Results in: $OUTFILE"
