#!/bin/bash

source common.sh

cat > dd_cmd.sh << EOF
#!/bin/bash

dd if=/dev/zero bs=1M count=500 of=foo
sync
EOF
chmod a+x dd_cmd.sh
DD="./dd_cmd.sh"

$DD > /dev/null 2>&1

for i in `seq 1 $REPTS`; do
	echo -n "."
	rm foo
	sync
	echo 3 > /proc/sys/vm/drop_caches
	power_start $i
	$TIME $DD > /dev/null 2>&1
	power_end $i
done
echo ""
