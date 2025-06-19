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
    export PATH="/home/code/buildroot/mybuildroot/output-ext/host/bin:${PATH}"
fi

#exec sudo env PATH="/home/code/buildroot/mybuildroot/output-ext/host/bin:${PATH}"  gdb --args qemu-system-x86_64 -M pc -kernel bzImage -drive file=rootfs.ext2,if=virtio,format=raw -append "rootwait root=/dev/vda console=tty1 console=ttyS0"  -net nic,model=virtio -net user  -device vfio-pci,host=0000:01:00.0,id=hostdev0  ${EXTRA_ARGS} "$@"
# exec qemu-system-x86_64 -M pc -kernel bzImage -drive file=rootfs.ext2,if=virtio,format=raw -append "rootwait root=/dev/vda console=tty1 console=ttyS0"  -net nic,model=virtio -net user  -device vfio-pci,host=0000:01:00.0,id=hostdev0  ${EXTRA_ARGS} "$@"
# qemu_log_mask

#    -trace enable=*pci*,file=qemu_trace-%d.log \
#        -qmp tcp:127.0.0.1:4444,server,nowait \
#    -serial telnet:127.0.0.1:6666,server,wait \

#exec qemu-system-x86_64 \
#    -chardev stdio,id=seabios -device isa-debugcon,iobase=0x402,chardev=seabios \
 #   -bios /home/code/buildroot/mybuildroot/qemu/qemu-9.2.0/roms/seabios/out/bios.bin \
  #  -d test,trace:*vfio*,trace:*pci* \
   # -D qemu_test_bios-%d.log 

exec qemu-system-x86_64 \
    -chardev pipe,path=qemudebugpipe,id=seabios -device isa-debugcon,iobase=0x402,chardev=seabios \
    -bios /home/code/buildroot/mybuildroot/qemu/qemu-9.2.0/roms/seabios/out/bios.bin \
    -d test,trace:*vfio*,trace:*pci* \
    -D qemu_test_bios-%d.log 