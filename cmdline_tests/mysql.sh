#!/bin/bash

ACTION=$1

function usage() {
	echo "Usage: $0 <prep|run|cleanup> [remoteserver] [repts]" >&2
	exit 1
}

SERVER=${2-localhost}	# dns/ip for machine to test
REPTS=${3-4}


NR_REQUESTS=1000
TABLE_SIZE=1000000
RESULTS=mysql.txt

if [[ "`whoami`" != "root" ]]; then
	echo "Please run as root" >&2
	exit 1
fi


if [[ "$SERVER" != "localhost" && ("$ACTION" == "prep" || "$ACTION" == "cleanup") ]]; then
	echo "prep and cleanup actions can only be run on the db server" >&2
	exit 1
fi

if [[ "$ACTION" == "prep" ]]; then
	# Prep
	service mysql start
	mysql -u root --password=kvm < create_db.sql
	sysbench --test=oltp --oltp-table-size=$TABLE_SIZE --mysql-password=kvm prepare
elif [[ "$ACTION" == "run" ]]; then
	# Exec
	for num_threads in 1 2 4 8 20 100 200 400; do
		echo -e "$num_threads threads:\n---" >> $RESULTS
		for i in `seq 1 $REPTS`; do
			sysbench --test=oltp --num-threads=$num_threads --mysql-password=kvm run | tee \
				>(grep 'total time:' | awk '{ print $3 }' | sed 's/s//' >> $RESULTS)
		done;
		echo "" >> $RESULTS
	done;
elif [[ "$ACTION" == "cleanup" ]]; then
	# Cleanup
	sysbench --test=oltp --mysql-password=kvm cleanup
	mysql -u root --password=kvm < drop_db.sql
	service mysql stop
else
	usage
fi
