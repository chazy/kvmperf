#!/bin/bash

source setup.sh

OUTPUT=""

function start_guest()
{
	ssh root@$HOST "$START_VM_COMMAND"
}

function shutdown_guest()
{
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

function common_test()
{
	uut="$1"	# unit under test
	remote="$2"	# dns/ip for machine to test
	tools="$3"	# list of tools in addition to $test.sh and common.sh

	cmdname="$1.sh"
	rand=$RANDOM
	remote_dir=/tmp/$1_$rand

	# Create remote directory, upload common scripts and tools
	ssh root@$remote "mkdir $remote_dir"
	scp -q "tests/common.sh" root@$remote:$remote_dir/.
	scp -q "tests/$cmdname" root@$remote:$remote_dir/.
	for t in "$tools"; do
		scp -q "tools/$t" root@$remote:$remote_dir/.
	done

	# Actually run the test command
	remote_cmd=""\
"chmod a+x $remote_dir/$cmdname && "\
"cd $remote_dir && "\
"./$cmdname > $uut.log 2>&1"
	ssh root@$remote "$remote_cmd"

	# Get time stats
	rm -f /tmp/time.txt
	scp root@$remote:$remote_dir/time.txt /tmp/time.txt
	tr '\n' '\t' < /tmp/time.txt
	rm -f /tmp/time.txt

	# Clean up
	ssh root@$remote "rm -rf $remote_dir"
}

function hackbench_test()
{
	common_test "$1" "$2" "hackbench"
}

TESTS="hackbench"

i=1
TESTS_ARR=( $TESTS )
total=${#TESTS_ARR[@]}
for TEST in "$TESTS"; do
	echo "============================================"
	echo "Test $i of $total ($TEST):"

	echo -n "native:"
	eval "${TEST}_test $TEST $HOST"

	start_guest > /tmp/kvmtest.log 2>&1 &

	wait_for_remote $GUEST1
	eval "${TEST}_test $TEST $GUEST1"

	shutdown_guest $GUEST1

	echo "============================================"
	echo -e "\n\n"
done
