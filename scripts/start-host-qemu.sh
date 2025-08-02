#!/bin/sh

BINARIES_DIR="${0%/*}/"
# shellcheck disable=SC2164
cd "${BINARIES_DIR}"

mode_serial=false
mode_sys_qemu=false
while [ "$1" ]; do
    case "$1" in
    --serial-only|serial-only) mode_serial=true; shift;;
    --use-system-qemu) mode_sys_qemu=true; shift;;
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
    export PATH="/home/ut/mybuildroot/output-ext/host/bin:${PATH}"
fi

touch nvm.img

exec  qemu-system-x86_64 -M q35 -kernel bzImage -drive file=rootfs.ext2,if=virtio,format=raw -append "rootwait root=/dev/vda console=tty1 console=ttyS0" \
       	-net nic,model=virtio -net user,hostfwd=tcp::2222-:22,hostfwd=tcp::1122-:1122 \
        -drive file=nvm.img,if=none,id=nvm \
        -device nvme,serial=deadbbbb,drive=nvm \
	-device intel-iommu \
	-m 1G \
	-d trace:*vfio*,trace:*pci* \
        -D host_qemu_test-%d.log \
	-msg timestamp=on \
        ${EXTRA_ARGS} "$@"
