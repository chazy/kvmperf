#!/bin/bash

source common.sh

dd if=/dev/urandom bs=1M count=500 of=foo > /dev/null 2>&1

cat > dd_cmd.sh << EOF
#!/bin/bash

dd if=foo bs=1M count=500 of=/dev/null
sync
EOF
chmod a+x dd_cmd.sh
DD="./dd_cmd.sh"

for i in `seq 1 $REPTS`; do
	echo -n "."
	rm bar
	sync
	echo 3 > /proc/sys/vm/drop_caches
	power_start $i
	$TIME $DD > /dev/null 2>&1
	power_end $i
done
echo ""
