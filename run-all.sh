#!/bin/bash

source setup.sh

HOST_DIR=""
GUEST_DIR=""
GUEST_ALIVE=0

echo "" > /tmp/kvmperf.log


trap 'early_exit; exit;' SIGINT SIGQUIT

early_exit()
{
	echo ""

	if [[ -n "$HOST_DIR" ]]; then
		echo -n "Removing temporary directory on the host..."
		ssh root@$HOST "umount $HOST_DIR/ram" > /dev/null 2>&1
		ssh root@$HOST "rm -rf $HOST_DIR"
		echo "done"
	fi
	if [[ -n "$GUEST_DIR" ]]; then
		echo -n "Removing temporary directory on the guest"
		ssh root@$GUEST1 "umount $GUEST_DIR/ram" > /dev/null 2>&1
		ssh root@$GUEST1 "rm -rf $GUEST_DIR"
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
	echo "Starting guest" >> $LOGFILE
	ssh -f root@$HOST 1>>$LOGFILE 2>&1 "$START_VM_COMMAND"
}

function shutdown_guest()
{
	GUEST_ALIVE=0
	echo "Shutting down guest" >> $LOGFILE
	ssh root@$GUEST1 "halt -p"
	sleep 3
	ssh root@$HOST "$SHUTDOWN_VM_COMMAND" >/dev/null 2>/dev/null
	sleep 1
}

function wait_for_remote()
{
	remote=$1
	echo "Waiting for $remote to become alive" >> $LOGFILE
	wait=1
	while [[ $wait == 1 ]]; do
		ping -q -c 1 $remote > /dev/null
		wait=$?
	done
	sleep 3
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
	echo "Uploading common scripts and tools" >> $LOGFILE
	ssh root@$remote "mkdir $remote_dir"
	$SCP ".localconf" root@$remote:$remote_dir/.
	$SCP "tests/common.sh" root@$remote:$remote_dir/.
	$SCP "tests/$cmdname" root@$remote:$remote_dir/.
	while [[ -n $1 ]]; do
		scp -q "$TOOLS/$1" root@$remote:$remote_dir/.
		shift 1
	done

	# Actually run the test command
	echo "Going to actually run the test" >> $LOGFILE
	remote_cmd=""\
"chmod a+x $remote_dir/$cmdname && "\
"cd $remote_dir && "\
"./$cmdname > $uut.log 2>&1"
	ssh -t root@$remote "$remote_cmd" 2>/dev/null
	if [[ $? == 255 ]]; then
		early_exit
	fi

	# Get time stats
	echo "Downloading time stats" >> $LOGFILE
	rm -f /tmp/time.txt
	$SCP root@$remote:$remote_dir/time.txt /tmp/time.txt
	tr '\n' '\t' < /tmp/time.txt
	echo ""

	# Clean up
	echo "Cleaning up" >> $LOGFILE
	ssh root@$remote "umount $remote_dir/ram > /dev/null 2>&1"
	ssh root@$remote "rm -rf $remote_dir"
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
	common_test "$1" "$2"
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

##########################################################################
# Test Harness
#

fn_exists()
{
    type $1 2>/dev/null | grep -q 'is a function' 1> /dev/null 2>&1
}

function run_test
{
	TEST="$1"
	RUN_IN_GUEST=$2

	if ! fn_exists "${TEST}_test"; then
		echo "Test function ${TEST}_test not defined!"
		return 1
	fi

	echo "($TEST):"

	echo -en "native:\t"
	eval "${TEST}_test $TEST $HOST"

	if [[ $RUN_IN_GUEST == 1 ]]; then
		start_guest

		wait_for_remote $GUEST1
		echo -en "   kvm:\t"
		eval "${TEST}_test $TEST $GUEST1"

		shutdown_guest $GUEST1
	fi

	return 0
}

#TESTS="hackbench untar curl1k curl1g dd_write dd_read dd_rw kernel_compile "
TESTS="hackbench untar curl1k curl1g kernel_compile "
HOST_TESTS="ws_arm"

if [[ -n "$1" ]]; then
	echo "$HOST_TESTS" | grep -q "\<$1\>"
	if [[ $? == 0 ]]; then
		run_test "$1" 0
	else
		run_test "$1" 1
	fi
else
	i=1
	TESTS=( $TESTS )
	HOST_TESTS=( $HOST_TESTS )
	total=$(( ${#TESTS[@]} + ${#HOST_TESTS[@]} ))
	for TEST in ${TESTS[@]}; do
		echo "============================================"
		echo -n "Test $i of $total "

		run_test "$TEST" 1

		echo "============================================"
		echo -e "\n\n"
		i=$(($i+1))
	done

	for TEST in ${HOST_TESTS[@]}; do
		echo "============================================"
		echo -n "Test $i of $total "

		run_test "$TEST" 0

		echo "============================================"
		echo -e "\n\n"
		i=$(($i+1))
	done
fi
