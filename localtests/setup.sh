TIME="/usr/bin/time --format=%e -o $TIMELOG --append"

KERNEL_NAME=linux-3.17
KERNEL="/tmp/$KERNEL_NAME"
KERNEL_TAR="$KERNEL.tar.gz"
KERNEL_XZ="$KERNEL.tar.xz"
KERNEL_BZ="$KERNEL.tar.xz.bz2"

uname -a | grep -q x86_64
if [[ $? == 0 ]]; then
	TOOLS=tools_x86
	x86=1
	arm64=0
else
	TOOLS=tools_arm64
	x86=0
	arm64=1
fi

refresh() {
	sync && echo 3 > /proc/sys/vm/drop_caches
	sleep 15
}


apt-get install -y time bc pbzip2 gawk wget

for i in time awk yes date bc pbzip2 wget
do
	iname=`which $i`
	if [[ ! -a $iname ]] ; then
		echo "$i not found in path, please install it; exiting"
		exit
	else
		echo "$i is found: $iname"
	fi
done

pushd /tmp
if [[ -d $KERNEL ]]; then
	echo "$KERNEL is here"
else
	if [[ -f $KERNEL_TAR ]]; then
		echo "$KERNEL_TAR is here"
	else
		echo "$KERNEL_TAR is not here"
		wget https://www.kernel.org/pub/linux/kernel/v3.x/linux-3.17.tar.gz
		sync
	fi
	echo "Extracing kernel tar..."
	tar xfz $KERNEL_TAR
fi

if [[ -f $KERNEL_XZ ]]; then
	echo "$KERNEL_XZ is here"
else
	echo "$KERNEL_XZ is not here"
	wget https://www.kernel.org/pub/linux/kernel/v3.x/linux-3.17.tar.xz
	sync
fi

if [[ -f $KERNEL_BZ ]]; then
	echo "$KERNEL_BZ is here"
else
	echo "$KERNEL_BZ is not here"
	pbzip2 -k -p2 -m500 $KERNEL_XZ
	sync
fi
popd
