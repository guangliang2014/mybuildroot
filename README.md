2025-5-23

# Setup

refs:
1.https://github.com/bootlin/buildroot-external-st.git

## 1, git submodule

   git submodule add https://github.com/guangliang2014/cbuildroot.git buildroot

   git submodule add https://github.com/guangliang2014/clinux.git linux

   git submodule add https://github.com/guangliang2014/cqemu.git qemu

   git submodule add https://github.com/guangliang2014/cbusybox.git busybox
   
   Success

   ### build origin(not test)

   make O=../../output -C buildroot/buildroot-2025.02 qemu_x86_64_defconfig

   make -C buildroot/buildroot-2025.02 O=../../output all 

   ### others

   menuconfig中的系统配置添加如下：

   open BR2_DL_DIR=$BR2_EXTERNAL_MY_PATH/../dl

   open BR2_CCACHE_DIR=$BR2_EXTERNAL_MY_PATH/../ccache  and BR2_CCACHE=y

        Notes: export CCACHE_DIR="/home/code/.ccache" in .bashrc will 覆盖buildroot的配置

               BR2_CCACHE_USE_BASEDIR=y 将使得所有的output目录来共享，而不至于更换output后，cache miss

## 2, BR2_EXTERNAL
   only an environment variable, Automatically saved in the hidden .br2-external.mk file
in the output directory.

   extenal.desc: NAME to define the BR2_EXTERNAL_MY_PATH,  this is the handle of this external



   System Config:

   1）配置BR2_PACKAGE_OVERRIDE_FILE=$BR2_EXTERNAL_MY_PATH/local.mk to using our source code

      be sure the source code is fit for buildroot/packages/*.mk

   2）ext_board/readme.txt and post-image.sh, ext_board/* using by System Configs

   3) packages using directly by buildroot framework

   ### build external

   make O=../../output-ext -C buildroot/buildroot-2025.02 BR2_EXTERNAL=../../external my_qemu_x86_64_defconfig  

   make O=../../output-ext -C buildroot/buildroot-2025.02  menuconfig  #change linux kernel version to 6.14.0  

   cp output-ext/.config  external/configs/my_qemu_x86_64_defconfig  

   make O=../../output-ext -C buildroot/buildroot-2025.02  all  

   The qemu & linux source must be using the right version!!  
## 3, init system

   Using Busybox(default)  
      Notice:  
      The BusyBox init program will read the /etc/inittab file at boot to know what to do.   
      The syntax of this file can be found in http://git.busybox.net/busybox/tree/examples/inittab (note that BusyBox   
      inittab syntax is special: do not use a random inittab documentation from the Internet to learn about BusyBox inittab).   
      The default inittab in Buildroot is stored in package/busybox/inittab. Apart from mounting a few important filesystems,   
      the main job the default inittab does is to start the /etc/init.d/rcS shell script, and start a getty program  
       (which provides a login prompt).  

## 4, /dev system
  
   Using udev(default is "devtmpfs only") + devtmpfs   
   
   kernel open CONFIG_UEVENT_HELPER for /proc/sys/kernel/hotplug  

  


## 5, Customize Linux & Qemu


### 5.1 Linux Config

   1) linux-menuconfig and linux-savedefconfig only work when linux is enabled  
   2) linux-savedefconfig  .config -->defconfig  
   3) cp output-ext/build/linux-custom/defconfig external/board/ext_board/linux.config  



## 6, Initrd & initramfs

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


## 7, Can work nvme disk

   DISK_ARGS="-drive file=nvme.img,if=none,id=D22 -device nvme,drive=D22,serial=1234"  
   nvme list  
   Node             SN                   Model                                    Namespace Usage                      Format           FW Rev  
   ---------------- -------------------- ---------------------------------------- --------- -------------------------- ---------------- --------
   /dev/nvme0n1     1234                 QEMU NVMe Ctrl                           1           4.29  GB /   4.29  GB    512   B +  0 B   9.2.0   

   Linux Trace


   Qemu Trace




## 8, Tools

   8.1 busybox lspci --> pciutils
   

## 9, add VFIO support

   9.1 host
    01:00.0 0108: 2646:5027 (rev 01) (prog-if 02 [NVM Express])  
    echo 0000:01:00.0 > /sys/bus/pci/drivers/nvme/unbind  
    echo 2646 5027 > /sys/bus/pci/drivers/vfio-pci/new_id  

   9.2 guest
     -device vfio-pci,host=0000:01:00.0,id=hostdev0  


## , Debug Qemu

## , Debug Linux

## , Debug APP












