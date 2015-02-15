#!/bin/bash

if [[ -f .localconf ]]; then
	source .localconf
else
	TESTARCH="arm"
	HOST="arndale"
	GUEST1="guest1"
	WEBHOST="webserver"
	POWERHOST="powerhost"
	USER="root"
	REPTS="10"

	echo -n "What's the architecture? [$TESTARCH]:"
	read _TESTARCH
	if [[ -n "$_TESTARCH" ]]; then
		TESTARCH="$_TESTARCH"
	fi

	echo -n "What's the DNS/IP of the host? [$HOST]:"
	read _HOST
	if [[ -n "$_HOST" ]]; then
		echo $_HOST
		HOST="$_HOST"
	else
		echo $_HOST
	fi

	echo -n "What's the DNS/IP of the guest? [$GUEST1]:"
	read _GUEST1
	if [[ -n "$_GUEST1" ]]; then
		GUEST1="$_GUEST1"
	fi

	echo -n "What's the DNS/IP of the web server? [$WEBHOST]:"
	read _WEBHOST
	if [[ -n "$_WEBHOST" ]]; then
		WEBHOST="$_WEBHOST"
	fi

	echo -n "What's the DNS/IP of the power measurement host? [$POWERHOST]:"
	read _POWERHOST
	if [[ -n "$_POWERHOST" ]]; then
		POWERHOST="$_POWERHOST"
	fi

	echo -n "How many repititions of each test do you want? [$REPTS]:"
	read _REPTS
	if [[ -n "$_REPTS" ]]; then
		REPTS="$_REPTS"
	fi

	echo -n "Username? [$USER]:"
	read _USER
	if [[ -n "$_USER" ]]; then
		USER="$_USER"
	fi

	echo "TESTARCH=\"$TESTARCH\"" > .localconf
	echo "HOST=\"$HOST\"" >> .localconf
	echo "GUEST1=\"$GUEST1\"" >> .localconf
	echo "WEBHOST=\"$WEBHOST\"" >> .localconf
	echo "POWERHOST=\"$POWERHOST\"" >> .localconf
	echo "REPTS=\"$REPTS\"" >> .localconf
	echo "USER=\"$USER\"" >> .localconf
fi

echo ""

# Commands
if [[ "$TESTARCH" == "x86" ]]; then
	#START_VM_COMMAND="virsh start guest1"
	#SHUTDOWN_VM_COMMAND="virsh -q destroy guest1"
	START_VM_COMMAND="/home/christoffer/bin/run-guest.sh"
	SHUTDOWN_VM_COMMAND="pkill kvm"
	TOOLS=tools_x86
	VM_CONSOLE=""
else
	TESTARCH="arm"
	VM_CONSOLE=/tmp/ubuntu.console
	START_VM_COMMAND="cd /root && ./run-guest.sh --serial $VM_CONSOLE -m 1536"
	SHUTDOWN_VM_COMMAND="pkill -9 qemu-system-arm"
	TOOLS=tools
fi
# Environment
IFS=$(echo -en "\n\t ")
LOGFILE=/tmp/kvmperf.log

# Select a good results file name
_OFN=1
if [[ -z "$OUTFILE" ]]; then
	echo -n "Test name?: "
	read OUTFILE
	if [[ -z "$OUTFILE" ]]; then
		exit 1
	fi
	OUTFILE=`basename $OUTFILE .txt`.txt
fi

_OF="$OUTFILE"
while [[ -e results/$_OF ]]; do
	_OF=`basename $OUTFILE .txt`-$_OFN.txt
	_OFN=$(( $_OFN + 1 ))
done
mkdir -p results
OUTFILE=results/"$_OF"


# Silent SCP command
SSCP="scp -q"
SCP="$SSCP"

# Silent SSH command
SSH="ssh"
SSSH="ssh -q 1>/dev/null 2>/dev/null"
