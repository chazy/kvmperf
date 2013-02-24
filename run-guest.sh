#!/bin/bash

SMP=2
MEMSIZE=512
DTB=/root/a15x2.dtb
KERNEL=zImage

HUGETLBFS=0
HUGE=""
VIRTIO=1
NOVIRTIO=0
CONSOLE=1
CONSOLE_FILE=""
IO_PARAMS=""
NET=1
APPEND=""
GDB=0

usage() {
	U=""
	if [[ -n "$1" ]]; then
		U="${U}$1\n\n"
	fi
	U="${U}Usage: $0 [options] <guest-name> \n\n"
	U="${U}Options:\n"
	U="$U    -c | --CPU <nr>:       Number of cores (default 2)\n"
	U="$U    -m | --mem <MB>:       Memory size (default 512)\n"
	U="$U    -H | --hugetlbfs:      Use hugetlbfs on /hugetlbfs\n"
	U="$U    -v | --virtio:         Use virtio block devices and networking\n"
	U="$U         --novirtio:       Don't use virtio (overrides --virtio)\n"
	U="$U         --no-net:         Don't setup any guest network\n"
	U="$U         --gdb:            Run QEMU in GDB\n"
	U="$U         --no-console:     Don't output any console\n"
	U="$U    -c | --console <file>: Output console to <file>\n"
	U="$U    -h | --help:           Show this output\n"
	U="${U}\n"
	U="${U}When specifying the guest-name, the system expects a file named\n"
	U="${U}<guest-name>.img which is a raw file system image of some sort\n"
	U="${U}which the guest kernel can read.\n"
	echo -e "$U" >&2
}

while :
do
	case "$1" in
	  -c | --cpu)
		SMP="$2"
		shift 2
		;;
	  -m | --mem)
		MEMSIZE="$2"
		shift 2
		;;
	  -H | --hugetlbfs)
		HUGETLBFS=1
		shift 1
		;;
	  -v | --virtio)
		if [[ $NOVIRTIO == 0 ]]; then
			VIRTIO=1
		else
			echo "warning: Overriding virtio with --novirtio" >&2
		fi
		shift 1
		;;
	  --no-net)
		NET=0
		shift 1
		;;
	  --gdb)
		GDB=1
		shift 1
		;;
	  --novirtio)
		VIRTIO=0
		NOVIRTIO=1
		shift 1
		;;
	  --no-console)
		CONSOLE=0
		shift 1
		;;
	  -c | --console)
		if [[ $CONSOLE == 0 ]]; then
			usage "Paremeter conflict: $1 and --no-console"
			exit 1
		fi
		CONSOLE_FILE="$2"
		shift 2
		;;
	  --append)
		APPEND="$2"
		shift 2
		;;
	  -h | --help)
		usage ""
		exit 1
		;;
	  --) # End of all options
		shift
		break
		;;
	  -*) # Unknown option
		echo "Error: Unknown option: $1" >&2
		exit 1
		;;
	  *)
		GUEST="$1"
		shift 1
		break
		;;
	esac
done

if [[ -z "$GUEST" ]]; then
	usage "error: guest not specified"
	exit 1
elif [[ -n "$1" ]]; then
	usage "error: unknown option: $1"
	exit 1
fi


IMG="$GUEST.img"
CONFFILE="$GUEST.conf"
ROOT_PART=""

rm -f $CONFFILE
echo "# qemu config file" >> $CONFFILE

function write_config_section()
{
	__SECTION="$1"
	echo -en "\n[${__SECTION}" >> $CONFFILE
	shift 1
	if [[ "$1" == "--id" ]]; then
		echo -n " \"${2}\"" >> $CONFFILE
		shift 2
	fi
	echo "]" >> $CONFFILE
	while [[ -n "$1" && -n "$2" ]]; do
		echo "  $1 = \"$2\"" >> $CONFFILE
		shift 2
	done
}

function write_id_section()
{
	___SECTION="$1"
	___ID="$2"
	shift 2
	write_config_section "$___SECTION" --id "$___ID" "$@"
}

function write_section()
{
	write_config_section "$@"
}


MACFILE=".$GUEST.mac"
if [[ -f "$MACFILE" ]]; then
	MAC=`cat $MACFILE`
else
	MAC=`printf 'DE:AD:BE:EF:%02X:%02X\n' $((RANDOM%256)) $((RANDOM%256))`
	echo "$MAC" > "$MACFILE"
fi

if [[ $HUGETLBFS == 1 ]]; then
	CUR=`cat /proc/sys/vm/nr_hugepages`
	NRPAGES=$(((MEMSIZE + 128) / 2))
	if [[ $CUR -lt $NRPAGES ]]; then
		echo $NRPAGES > /proc/sys/vm/nr_hugepages
	fi

	HUGE="-mem-path /hugetlbfs"
fi


BOOT_CMD="console=ttyAMA0 mem=${MEMSIZE}M earlyprintk debug"

if [[ $VIRTIO == 1 ]]; then
	#IO_PARAMS="$IO_PARAMS -drive if=none,file=${IMG},id=vda"
	write_id_section drive vda if none file "$IMG" cache writethrough

	#IO_PARAMS="$IO_PARAMS -device virtio-blk,transport=virtio-mmio.0,drive=vda"
	write_section device driver virtio-blk transport virtio-mmio.0 drive vda

	if [[ $NET == 1 ]]; then
		#IO_PARAMS="$IO_PARAMS -netdev tap,id=tap0"
		write_id_section netdev tap0 "type" tap
		#IO_PARAMS="$IO_PARAMS -device virtio-net,transport=virtio-mmio.1,netdev=tap0,mac=$MAC"
		write_section device driver virtio-net transport virtio-mmio.1 netdev tap0 mac $MAC
	else
		echo "warning: no network!" >&2
	fi
	BOOT_CMD="$BOOT_CMD virtio_mmio.device=1K@0x4e000000:74:0"
	BOOT_CMD="$BOOT_CMD virtio_mmio.device=1K@0x4e100000:75:1"
	BOOT_CMD="$BOOT_CMD virtio_mmio.device=1K@0x4e200000:76:2"
	BOOT_CMD="$BOOT_CMD root=/dev/vda${ROOT_PART} rw rootfstype=ext4"
else
	IO_PARAMS="$IO_PARAMS -sd $IMG"
	if [[ $NET == 1 ]]; then
		IO_PARAMS="$IO_PARAMS -net nic"
		IO_PARAMS="$IO_PARAMS -net tap,vlan=0,ifname=tap0,downscript=no"
	fi

	if [[ -n "$ROOT_PART" ]]; then
		ROOT_PART="p$ROOT_PART"
	fi
	BOOT_CMD="$BOOT_CMD root=/dev/mmcblk0${ROOT_PART} rw"
fi

BOOT_CMD="$BOOT_CMD init=/sbin/init --no-log noplymouth"

(write_section machine dtb $DTB kernel $KERNEL  accel kvm append "$BOOT_CMD" kernel_irqchip on)

if [[ $CONSOLE == 0 ]]; then
	CONS="-serial null -display none"
elif [[ -n "$CONSOLE_FILE" ]]; then
	CONS="-serial file:$CONSOLE_FILE -display none"
else
	CONS="-nographic"
fi

#./qemu-system-arm \
ARGS="\
	-smp $SMP \
	$IO_PARAMS \
	$HUGE \
	-m $MEMSIZE -M vexpress-a15 -cpu cortex-a15 \
	-readconfig $CONFFILE \
	$CONS"

echo $ARGS

if [[ $GDB == 1 ]]; then
	gdb --args ./qemu-system-arm $ARGS
else
	./qemu-system-arm $ARGS
fi
