Run the emulation with:

  qemu-system-x86_64 -M q35 -kernel output/images/bzImage -drive file=output/images/rootfs.ext2,if=virtio,format=raw -append "rootwait root=/dev/vda console=tty1 console=ttyS0 loglevel=3 quiet" -serial stdio -net nic,model=virtio -net user # qemu_x86_64_defconfig

Optionally add -smp N to emulate a SMP system with N CPUs.

The login prompt will appear in the graphical window.
