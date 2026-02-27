#!/bin/sh

BINARIES_DIR="${0%/*}/"
# shellcheck disable=SC2164
cd "${BINARIES_DIR}"

mode_serial=false
mode_sys_qemu=false
mode_net=false
while [ "$1" ]; do
    case "$1" in
    --serial-only|serial-only) mode_serial=true; shift;;
    --use-system-qemu) mode_sys_qemu=true; shift;;
    --network) mode_net=true; shift;;
    --) shift; break;;
    *) echo "unknown option: $1" >&2; exit 1;;
    esac
done

if ${mode_serial}; then
    EXTRA_ARGS='-nographic'
else
    EXTRA_ARGS='-serial stdio'
fi

if ! ${mode_sys_qemu}; then
    export PATH="/home/code/pcie/mybuildroot/output-kitos/host/bin:${PATH}"
fi


# If no X DISPLAY is configured, force headless display so QEMU won't
# fail initializing SDL. Users can still override by passing display
# related options on the command line.
if [ -z "${DISPLAY}" ]; then
    case " ${EXTRA_ARGS} " in
        *" -display "*|*" -nographic "*)
            ;;
        *)
            EXTRA_ARGS="${EXTRA_ARGS} -display none"
            echo "No DISPLAY set; forcing headless: using '-display none'" >&2
            ;;
    esac
fi

NET_ARGS=''
if ${mode_net} ; then
    NET_ARGS='-net nic,model=virtio -net user'
    echo "Network enabled for this run" >&2
fi

# normalize
BDF="0000:01:00.0"

exec qemu-system-x86_64 -M pc -kernel bzImage -drive file=rootfs.ext2,if=virtio,format=raw -append "rootwait root=/dev/vda console=tty1 console=ttyS0 loglevel=3 quiet" ${NET_ARGS} -device vfio-pci,host=$BDF,id=hostdev0 ${EDU_DEV_ARG} ${EXTRA_ARGS} "$@"
