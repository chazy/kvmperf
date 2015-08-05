source tests/power.sh

function mysql_remote_test()
{
	uut="$1"	# unit under test
	remote="$2"	# dns/ip for machine to test
        clientIP=$(ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}')
	shift 2

	echo "Client IP is $clientIP"
	echo "[Server] Make sure mysql and sysbench are installed and disabled"
	ssh $USER@$remote "cat > /tmp/i.sh && chmod a+x /tmp/i.sh && sudo /tmp/i.sh" < tests/mysql_install.sh | \
		tee -a $LOGFILE
	
	echo "[Server] Allow remote access to mysql"
	ssh $USER@$remote "sudo sed -i 's/^bind/#bind/g' /etc/mysql/my.cnf"

	echo "[Server] Prep"
	sed 's/remote/'$clientIP'/g' tests/create_db_remote.sql > tests/create_db_remote_tmp_.sql
	$SCP tests/*.sql $USER@$remote:/tmp/.
	ssh $USER@$remote "sudo service mysql start" | tee -a $LOGFILE
	ssh $USER@$remote "sudo mysql -u root --password=kvm < /tmp/create_db_remote_tmp.sql" | tee -a $LOGFILE

	echo "[Client] Make sure mysql and sysbench are installed and disabled"
	chmod +x ./tests/mysql_install.sh
	sudo ./tests/mysql_install.sh
	echo "[Client] Prep"
	sudo service mysql start
	sysbench --test=oltp --mysql-password=kvm --oltp-table-size=1000000 --mysql-host=$remote prepare | tee -a $LOGFILE

	MYSQL_STARTED="$remote"
	rm -f /tmp/power.values.*
	POWEROUT=/tmp

	# Exec
	rm -f /tmp/time.txt
	touch /tmp/time.txt
	
	for j in 1 2 4 8 20 100 200 400; do
		for i in `seq 1 $REPTS`; do
			power_start $i
			sysbench --test=oltp --mysql-password=kvm --oltp-table-size=1000000 --mysql-host=$remote --num-threads=$j run | tee \
				>(grep 'total time:' | awk '{ print $3 }' | sed 's/s//' >> /tmp/time.txt)
			power_end $i
		done;
	done;

	# Cleanup
	sysbench --test=oltp --mysql-password=kvm --mysql-host=$remote cleanup| tee -a $LOGFILE
	ssh $USER@$remote "sudo mysql -u root --password=kvm < /tmp/drop_db.sql" | tee -a $LOGFILE

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


	ssh $USER@$remote "service mysql stop" | tee -a $LOGFILE
	MYSQL_STARTED=""
}

