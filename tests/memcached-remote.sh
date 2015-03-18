function memcached_test()
{
	uut="$1"	# unit under test
	remote="$2"	# dns/ip for machine to test
	#REPTS=1

	MEMCACHED=libmemcached-1.0.15
	MEMCACHED_CONF=memcached.conf
	TIMELOG=$OUTFILE
	TIME="/usr/bin/time --format=%e -o $TIMELOG --append"
	
	cp tools/$MEMCACHED.tar.gz /tmp
	sudo ./tests/memcached_install.sh

	# Make sure memcached and memslap are installed
	$SCP tools/$MEMCACHED.tar.gz $USER@$remote:~/$MEMCACHED.tar.gz
	ssh $USER@$remote "sudo cp ~/$MEMCACHED.tar.gz /tmp/"
	ssh $USER@$remote "sudo cat > /tmp/i.sh && sudo chmod a+x /tmp/i.sh && sudo /tmp/i.sh" < tests/memcached_install.sh
	ssh $USER@$remote "sudo sed s/127.0.0.1/$remote/g /etc/$MEMCACHED_CONF > /tmp/i.conf"
	ssh $USER@$remote "cp /tmp/i.conf /etc/$MEMCACHED_CONF"
	ssh $USER@$remote "rm /tmp/i.conf"

	ssh $USER@$remote "sudo service memcached restart"
	CMD="sudo memslap --servers $remote:11211 --concurrency=100"

	rm -f $TIMELOG 
	touch $TIMELOG

	for i in `seq 1 $REPTS`; do
		echo " *** Test $i of $REPTS ***"
			$TIME $CMD
			done

	ssh $USER@$remote "sudo service memcached stop"

	#tr '\n' '\t' < $TIMELOG

	# Output in nice format as well
	echo -en " $uut (${remote})\t" >> $TIMELOG
	echo "" >> $TIMELOG

}
