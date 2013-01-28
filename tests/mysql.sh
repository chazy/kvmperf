source tests/power.sh

function mysql_test()
{
	uut="$1"	# unit under test
	remote="$2"	# dns/ip for machine to test
	shift 2

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
	rm -f /tmp/power.values.*
	POWEROUT=/tmp

	# Exec
	rm -f /tmp/time.txt
	touch /tmp/time.txt
	for i in `seq 1 $REPTS`; do
		power_start $i
		ssh root@$remote "sysbench --test=oltp --mysql-password=kvm run" | tee \
			>(grep 'total time:' | awk '{ print $3 }' | sed 's/s//' >> /tmp/time.txt)
		power_end $i
	done;

	# Cleanup
	ssh root@$remote "sysbench --test=oltp --mysql-password=kvm cleanup" | tee -a $LOGFILE
	ssh root@$remote "mysql -u root --password=kvm < /tmp/drop_db.sql" | tee -a $LOGFILE

	# Get time stats
	echo "Requests per second" >> $LOGFILE
	tr '\n' '\t' < /tmp/time.txt
	echo ""

	# Output in nice format as well
	echo -en " $uut (${remote})\t" >> $OUTFILE
	cat /tmp/time.txt | tr '\n' '\t' >> $OUTFILE
	echo >> $OUTFILE

	# Get power stats
	if [[ $DO_POWER == 1 ]]; then
		echo "Downloading power stats" | tee -a $LOGFILE
		echo -en " $uut (${remote} - power)\t" >> $OUTFILE
		for powerfile in `ls -1 /tmp/power.values.*`; do
			piter=`basename "$powefile" | awk -F . '{print $NF}'`
			cat $powerfile | ./avg >> $OUTFILE
			echo -en "\t" >> $OUTFILE
		done
		echo "" >> $OUTFILE
	fi


	ssh root@$remote "service mysql stop" | tee -a $LOGFILE
	MYSQL_STARTED=""
}

