function mysql_test()
{
	uut="$1"	# unit under test
	remote="$2"	# dns/ip for machine to test
	shift 2

	ab=`which ab`

	NR_REQUESTS=1000

	# Make sure apache and sysbench are installed and disabled
	ssh root@$remote "cat > /tmp/i.sh && chmod a+x /tmp/i.sh && /tmp/i.sh" < tests/mysql_install.sh | \
		tee -a $LOGFILE

	# Prep
	$SCP tests/*.sql root@$remote:/tmp/.
	ssh root@$remote "service mysql start" | tee -a $LOGFILE
	ssh root@$remote "mysql -u root --password=kvm < /tmp/create_db.sql" | tee -a $LOGFILE
	ssh root@$remote "sysbench --test=oltp --mysql-password=kvm prepare" | tee -a $LOGFILE

	MYSQL_STARTED="$remote"

	# Exec
	rm -f /tmp/time.txt
	touch /tmp/time.txt
	for i in `seq 1 $REPTS`; do
		ssh root@$remote "sysbench --test=oltp --mysql-password=kvm run" | tee \
			>(grep 'total time:' | awk '{ print $3 }' | sed 's/s//' >> /tmp/time.txt)
	done;

	# Cleanup
	ssh root@$remote "sysbench --test=oltp --mysql-password=kvm cleanup" | tee -a $LOGFILE
	ssh root@$remote "mysql -u root --password=kvm < /tmp/drop_db.sql" | tee -a $LOGFILE

	# Get time stats
	echo "Requests per second" >> $LOGFILE
	tr '\n' '\t' < /tmp/time.txt
	echo ""

	# Output in nice format as well
	echo -en "$uut (${remote})\t" >> $OUTFILE
	cat /tmp/time.txt | tr '\n' '\t' >> $OUTFILE
	echo >> $OUTFILE

	ssh root@$remote "service mysql stop" | tee -a $LOGFILE
	MYSQL_STARTED=""
}

