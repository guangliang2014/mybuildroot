# Brief

Date@2025-8-2

## Summary
This git repo save my minisys and fullsys buildroot build environment.
  minisys has a small rootfs, about 60MB;
  fullsys has a full rootfs, qemu, sshd and so on, about 600MB.

And, we can add custom code into linux, qemu, busybox and buildroot.


## How setup this repo:
1, git submodule
   <code>git submodule add https://github.com/guangliang2014/cbuildroot.git buildroot </code> 
   <code>git submodule add https://github.com/guangliang2014/clinux.git linux </code> 
   <code>git submodule add https://github.com/guangliang2014/cqemu.git qemu </code> 
   <code>git submodule add https://github.com/guangliang2014/cbusybox.git busybox </code> 

   build steps:
   make O=../../output -C buildroot/buildroot-2025.02 qemu_x86_64_defconfig
   make -C buildroot/buildroot-2025.02 O=../../output all 
2, DL and CCache:
   <code>BR2_DL_DIR="\$(TOPDIR)/../../dl"</code> 
   <code>BR2_CCACHE_DIR="\$(TOPDIR)/../../ccache"  and BR2_CCACHE=y </code> 
   
   Notes: export CCACHE_DIR="/home/code/.ccache" in .bashrc will 覆盖buildroot的配置 
               BR2_CCACHE_USE_BASEDIR=y 将使得所有的output目录来共享，而不至于更换output后，cache miss  ???? 

3, Create BR2_EXTERNAL
   It is an environment variable, saved in the hidden .br2-external.mk file in the output directory.
   extenal.desc: NAME to define the BR2_EXTERNAL_MY_PATH,  this is the handle of this external

4, OVERRIDE config 
   1) 配置BR2_PACKAGE_OVERRIDE_FILE=$BR2_EXTERNAL_MY_PATH/local.mk to using our source code
      be sure the source code is fit for buildroot/packages/*.mk
   2) ext_board/readme.txt and post-image.sh, ext_board/* using by System Configs
   3) packages using directly by buildroot framework


## How to build  
1, Setup  
   make O=../../output-ext -C buildroot/buildroot-2025.02 BR2_EXTERNAL=../../external my_qemu_x86_64_defconfig  
2, Build 
   make O=../../output-ext -C buildroot/buildroot-2025.02  menuconfig  #change linux kernel version to 6.14.0
   make O=../../output-ext -C buildroot/buildroot-2025.02  all
3, Configure
   make O=../../output-ext -C buildroot/buildroot-2025.02  linux-savedefconfig
   make O=../../output-ext -C buildroot/buildroot-2025.02  savedefconfig
4, Help
   make O=../../output-ext -C buildroot/buildroot-2025.02  help
5, Toolchain
   make O=../../output-ext -C buildroot/buildroot-2025.02  toolchain
6, SDK
   make O=../../output-ext -C buildroot/buildroot-2025.02  sdk  

#### Linux Init System  
   Using Busybox(default)  
      Notice:  
      The BusyBox init program will read the /etc/inittab file at boot to know what to do.   
      The syntax of this file can be found in http://git.busybox.net/busybox/tree/examples/inittab (note that BusyBox   
      inittab syntax is special: do not use a random inittab documentation from the Internet to learn about BusyBox inittab).   
      The default inittab in Buildroot is stored in package/busybox/inittab. Apart from mounting a few important filesystems,   
      the main job the default inittab does is to start the /etc/init.d/rcS shell script, and start a getty program  
       (which provides a login prompt).  
 
   /dev system
  
   Using udev(default is "devtmpfs only") + devtmpfs !!  
   kernel open CONFIG_UEVENT_HELPER for /proc/sys/kernel/hotplug  

  
#### Linux Config System
   BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE="\$(BR2_EXTERNAL_MY_PATH)/board/ext_board/linux.config"  

#### Initrd & initramfs

   6.1 Initrd = Init ram disk   
      bootloader会把initrd文件读到内存中，然后把initrd文件在内存中的起始地址和大小传递给内核  
      //linuxrc -->    cpio /init; image /initrc  
      //mem=32M console=ttySAC0 root=/dev/ram initrd=0xc1000000,0x00600000 ramdisk_size=8192 rw  

   6.2 initramfs
      cpio格式的文件被打包到kernel文件中  
      __initramfs_start和__initramfs_end  

   6.3 (default)noinitrd方式:
      Kernel  
      [N]Initial RAM filesystem and RAM disk (initramfs/initrd) support  

      bzImage（binwalk not found initramfs)  
         DECIMAL       HEXADECIMAL     DESCRIPTION
         --------------------------------------------------------------------------------
         17092         0x42C4          gzip compressed data, maximum compression, from Unix, last modified: 1970-01-01 00:00:00 (null date)
      command line: rootwait root=/dev/vda

      /linuxrc --> busybox ( /etc/inittab )  or systemd  

#### Peripherals
   DISK_ARGS="-drive file=nvme.img,if=none,id=D22 -device nvme,drive=D22,serial=1234" 

#### Tools  
   busybox lspci --> pciutils  
   

#### VFIO support
   *host*
    01:00.0 0108: 2646:5027 (rev 01) (prog-if 02 [NVM Express])  
    echo 0000:01:00.0 > /sys/bus/pci/drivers/nvme/unbind  
    echo 2646 5027 > /sys/bus/pci/drivers/vfio-pci/new_id  
    vfio_bind.sh  
     
   *guest*
   -device vfio-pci,host=0000:01:00.0,id=hostdev0   
   file your_binary 查看文件是否带debug信息、是否strip？  strip、debug信息、-og？？  
   exec sudo env PATH="/home/code/buildroot/mybuildroot/output-ext/host/bin:\${PATH}"  gdb --args qemu-system-x86_64 -M pc 
      -kernel bzImage -drive file=rootfs.ext2,if=virtio,format=raw -append "rootwait root=/dev/vda console=tty1 console=ttyS0" 
      -net nic,model=virtio -net user  -device vfio-pci,host=0000:01:00.0,id=hostdev0  ${EXTRA_ARGS} "\$@"  

   *vfio 设备权限问题解决*
   sudo usermod -aG vfio $USER  
   sudo chown root:vfio /dev/vfio/*  
   sudo chmod 660 /dev/vfio/*  
   
   临时修改权限：sudo chmod 666 /dev/vfio/*  

#### GDB VSCode  

   1) launch.json   for gdb host app

      {
      "version": "0.2.0",
      "configurations": [
        {
            "name": "Debug QEMU with GDB",
            "type": "cppdbg",
            "request": "launch",
            "program": "/home/code/buildroot/mybuildroot/output-ext/host/bin/qemu-system-x86_64",
            "args": [
                "-M", "pc",  
                "-kernel", "bzImage",
                "-drive", "file=rootfs.ext2,if=virtio,format=raw",
                "-append", "rootwait root=/dev/vda console=tty1 console=ttyS0",
                "-net", "nic,model=virtio",
                "-net", "user",
                "-device", "vfio-pci,host=0000:01:00.0,id=hostdev0"
            ],
            "stopAtEntry": true,
            "cwd": "/home/code/buildroot/mybuildroot/output-ext/images",
            "environment": [
                {
                    "name": "PATH",
                    "value": "/home/code/buildroot/mybuildroot/output-ext/host/bin:${env:PATH}"
                }
            ],
            "externalConsole": false,
            "MIMode": "gdb",
            "miDebuggerPath": "/usr/bin/gdb", // 或你的 gdb 路径
            "setupCommands": [
                { "description": "Enable pretty-printing", "text": "-enable-pretty-printing", "ignoreFailures": true }
            ]
        },
    ]
   }</code>

   2, for linux kernel ??

   3, for guest app ??

   4, for seabios ??

#### b\.sh
   fullsys setup xxxx.config
   fullsys all

#### Others
Tips:
1， qemu编译失败，提示“fatal: this operation must be run in a work tree”
优先执行：
meson subprojects download
或者执行：
rm -rf subprojects/keycodemapdb
git clone https://gitlab.com/qemu-project/keycodemapdb.git subprojects/keycodemapdb
cd subprojects/keycodemapdb
git checkout f5772a62ec52591ff6870b7e8ef32482371f22c6

qemu需要从网站上下载压缩包，不能使用git clone。否则会有编译问题。

2, 多用户环境下ccache冲突问题解决办法
<code>export CCACHE_DIR="\$HOME/.ccache_$USER"</code>

3, qemu subprojects download error:
  Download bilge-impl-0.2-rs...
  -> Diff file "subprojects/packagefiles/bilge-impl-1.63.0.patch" does not exist
  WARNING: Please check logs above as command failed in some subprojects which could have been left in conflict state: bilge-impl-0.2-rs
