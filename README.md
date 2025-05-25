2025-5-23

# Setup

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

## 3, Customize Linux & Qemu(TODO)











