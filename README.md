2025-5-23

# Setup

1, git submodule add https://github.com/guangliang2014/cbuildroot.git buildroot
   git submodule add https://github.com/guangliang2014/clinux.git linux
   git submodule add https://github.com/guangliang2014/cqemu.git qemu
   git submodule add https://github.com/guangliang2014/cbusybox.git busybox
   
   Success

2, BR2_EXTERNAL, only an environment variable, Automatically saved in the hidden .br2-external.mk file
in the output directory

extenal.desc: NAME to define the BR2_EXTERNAL_MY_PATH,  this is the handle of this external

3, mkdir clinux, cqemu to save clean code from mylinux and myqemu

   make O=../output-ext -C buildroot  qemu-rebuild all  to using the lasted source code

4, build origin buildroot to output
   make O=../output -C buildroot qemu_x86_64_defconfig
   make -C buildroot O=../output all 
Success

5, build external into output-ext to test cqemu
   make O=../output-ext -C buildroot BR2_EXTERNAL=../external my_qemu_x86_64_defconfig

   make -C buildroot O=../output-ext menuconfig
     # to open BR2_DL_DIR=$BR2_EXTERNAL_MY_PATH/../dl   default is buildroot/dl
     # to open BR2_CCACHE_DIR=$BR2_EXTERNAL_MY_PATH/../ccache  and BR2_CCACHE=y
     #Notes: export CCACHE_DIR="/home/code/.ccache" in .bashrc will 覆盖buildroot的配置
     #       BR2_CCACHE_USE_BASEDIR=y 将使得所有的output目录来共享，而不至于更换output后，cache miss
   # save buildroot config file 
   cp output-ext/.config  extenal/configs/my_qemu_x86_64_defconfig

   需要配置BR2_PACKAGE_OVERRIDE_FILE=$BR2_EXTERNAL_MY_PATH/local.mk to using our source code
   !!!如果编译不过，可以make clean all
   !!!主要原因是，buildroot的package/*.mk与自己准备的source code可能不对应。

   make -C buildroot O=../output-ext all 

   !!! mybuildroot/output/images/start-qemu.sh 无法生产，原因是在package/post-images.sh会去找支持该配置的readme.txt，新扩展的配置是没有对应的readme.txt的。
   # 指定了新的扩展post-image.sh在extern/board/目录下面
   # 新qemu需要打开BR2_PACKAGE_QEMU_SLIRP  target/misc/qemu/BR2_PACKAGE_QEMU_SLIRP
   # externl readme.txt for qemu

   # fix all cxxx repos base is clean to backup list

6, add cbusybox
   1， source code
   2， config
   

7，add clinux






##Step##
1, build the default config
make -C buildroot O=output BR2_EXTERNAL=extenal my_qemu_x86_64_defconfig

2, build others
make -C buildroot O=output-ext BR2_EXTERNAL=extenal1  qemu_x86_64_defconfig

3, build linux and clean linux

4, build qemu and clean qemu

5, add the etc into rootfs

6, overlay the rootfs with the new bin

7, add the new bin to the rootfs
   NVMe-cli from mynvme
   FIO from myfio

8, change buildroot config
9, change linux config
10, chang busybox config

11, gdb Debug qemu
12, gdb Debug kernel
13, gdb bin
14, remote gdb debug






