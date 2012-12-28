function apache_test()
{
	uut="$1"	# unit under test
	remote="$2"	# dns/ip for machine to test
	shift 2

	ab=/usr/bin/ab

	NR_REQUESTS=1000

	# Make sure apache is installed and disabled
	ssh root@$remote "cat > /tmp/i.sh && chmod a+x /tmp/i.sh && /tmp/i.sh" < tests/apache_install.sh | \
		tee -a $LOGFILE

	$SCP tools/gcc-html.tar.gz root@$remote:/var/www/.
	ssh root@$remote "cd /var/www; tar xzf gcc-html.tar.gz" | tee -a $LOGFILE
	ssh root@$remote "service apache2 start" | tee -a $LOGFILE
	APACHE_STARTED="$remote"

	rm -f /tmp/time.txt
	touch /tmp/time.txt
	for i in `seq 1 $REPTS`; do
		$ab -n $NR_REQUESTS -c 100 http://$remote/gcc/index.html | \
			tee >(grep 'Requests per second' | awk '{ print $4 }' >> /tmp/time.txt)
	done;

	# Get time stats
	echo "Requests per second" >> $LOGFILE
	tr '\n' '\t' < /tmp/time.txt
	echo ""

	# Output in nice format as well
	echo -en " $uut (${remote})\t" >> $OUTFILE
	cat /tmp/time.txt | tr '\n' '\t' >> $OUTFILE
	echo >> $OUTFILE

	ssh root@$remote "service apache2 stop" | tee -a $LOGFILE
	APACHE_STARTED=""
}

