#!/bin/bash

source setup.sh

HOST_DIR=""
GUEST_DIR=""
GUEST_ALIVE=0


trap 'early_exit; exit;' SIGINT SIGQUIT

early_exit()
{
	echo ""
	if [[ -n "$HOST_DIR" ]]; then
		echo -n "Removing temporary directory on the host..."
		ssh root@$HOST "rm -rf $HOST_DIR"
		echo "done"
	fi
	if [[ -n "$GUEST_DIR" ]]; then
		echo -n "Removing temporary directory on the guest"
		ssh root@$GUEST1 "rm -rf $GUEST_DIR"
		echo "done"
	fi
	if [[ $GUEST_ALIVE == 1 ]]; then
		echo -n "Shutting down VM..."
		shutdown_guest
		echo "done"
	fi
	echo "Exiting!"
}

function start_guest()
{
	GUEST_ALIVE=1
	ssh -f root@$HOST 1>/tmp/kvmtest.log 2>&1 "$START_VM_COMMAND"
}

function shutdown_guest()
{
	GUEST_ALIVE=0
	ssh root@$GUEST1 "halt -p"
	sleep 3
	ssh root@$HOST "pkill -9 qemu-system-arm"
	sleep 1
}

function wait_for_remote()
{
	remote=$1
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

function common_test()
{
	uut="$1"	# unit under test
	remote="$2"	# dns/ip for machine to test
	tools="$3"	# list of tools in addition to $test.sh and common.sh

	cmdname="$1.sh"
	rand=$RANDOM
	remote_dir=/tmp/$1_$rand
	set_remote_dir "$remote_dir"

	# Create remote directory, upload common scripts and tools
	ssh root@$remote "mkdir $remote_dir"
	$SCP "tests/common.sh" root@$remote:$remote_dir/.
	$SCP "tests/$cmdname" root@$remote:$remote_dir/.
	if [[ -n "$tools" ]]; then
		for t in "$tools"; do
			scp -q "tools/$t" root@$remote:$remote_dir/.
		done
	fi

	# Actually run the test command
	remote_cmd=""\
"chmod a+x $remote_dir/$cmdname && "\
"cd $remote_dir && "\
"./$cmdname > $uut.log 2>&1"
	ssh root@$remote "$remote_cmd"

	# Get time stats
	rm -f /tmp/time.txt
	$SCP root@$remote:$remote_dir/time.txt /tmp/time.txt
	tr '\n' '\t' < /tmp/time.txt
	echo ""

	# Clean up
	ssh root@$remote "rm -rf $remote_dir"
	set_remote_dir ""
}

###########################################################################
# Here follows hackbench results
#

function hackbench_test()
{
	common_test "$1" "$2" "hackbench"
}

function kernel_compile_test()
{
	common_test "$1" "$2" ""
}

function untar_test()
{
	common_test "$1" "$2" ""
}

function curl1k_test()
{
	common_test "$1" "$2" ""
}

function curl1g_test()
{
	common_test "$1" "$2" ""
}

function dd_write_test()
{
	common_test "$1" "$2" ""
}

function dd_read_test()
{
	common_test "$1" "$2" ""
}

function dd_rw_test()
{
	common_test "$1" "$2" ""
}

##########################################################################
# Test Harness
#

function run_test
{
	TEST="$1"
	echo "($TEST):"

	echo -en "native:\t"
	eval "${TEST}_test $TEST $HOST"

	start_guest

	wait_for_remote $GUEST1
	echo -en "   kvm:\t"
	eval "${TEST}_test $TEST $GUEST1"

	shutdown_guest $GUEST1
}

TESTS="hackbench kernel_compile untar curl_1k curl_1g dd_write dd_read dd_rw"

if [[ -n "$1" ]]; then
	run_test "$1"
else
	i=1
	TESTS=( $TESTS )
	total=${#TESTS[@]}
	for TEST in ${TESTS[@]}; do
		echo "============================================"
		echo -n "Test $i of $total "

		run_test "$TEST"

		echo "============================================"
		echo -e "\n\n"
		i=$i+1
	done
fi
