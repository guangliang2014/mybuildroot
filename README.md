   # Brief

   _Date: 2025-08-02_

   _Update: 2026-01-21_

   ## Summary

   This git repo stores my minisys and fullsys Buildroot build environments.

   - `minisys` has a small rootfs (~60MB).
   - `fullsys` has a full rootfs, QEMU, SSHD, etc. (~600MB).

   Two boards are added:

   1. `pcie` — creates a full PCIe hardware platform, includes IOMMU device, custom PCIe/NVMe device, test device, and a full
      Linux/rootfs that integrates apt, qemu and a small OS/Rootfs for testing.
      The one platform for all tests.
   2. `kitos` — a smaller OS/Rootfs that can been included in `pcie`. Build `kitos` first, then `pcie`.

   You can add custom code into `linux`, `qemu`, `busybox` and Buildroot.

   ## 仓库创建步骤

   1. Add git submodules:

   ```bash
   git submodule add https://github.com/guangliang2014/cbuildroot.git buildroot
   git submodule add https://github.com/guangliang2014/clinux.git linux
   git submodule add https://github.com/guangliang2014/cqemu.git qemu
   git submodule add https://github.com/guangliang2014/cbusybox.git busybox
   ```

   原始构建步骤：

   ```bash
   make O=../../output -C buildroot/buildroot-2025.02 qemu_x86_64_defconfig
   make -C buildroot/buildroot-2025.02 O=../../output all
   ```

   2. DL 和 CCache 配置示例：

   ```makefile
   BR2_DL_DIR="$(TOPDIR)/../../dl"
   BR2_CCACHE_DIR="$(TOPDIR)/../../ccache"
   BR2_CCACHE=y
   ```

   Notes: `export CCACHE_DIR="/home/code/.ccache"` in `.bashrc` will override Buildroot config. `BR2_CCACHE_USE_BASEDIR=y` lets different outputs share cache.

   3. 创建 BR2_EXTERNAL

   BR2_EXTERNAL 是一个环境变量，会保存在 output 目录下的 `.br2-external.mk`。`external.desc` 中的 NAME 用来定义 `BR2_EXTERNAL_<NAME>_PATH`。

   4. OVERRIDE 配置

   - 配置 `BR2_PACKAGE_OVERRIDE_FILE=$(BR2_EXTERNAL_MY_PATH)/local.mk` 以使用本地源码（确保源码符合 `package/*.mk` 要求）。
   - `ext_board/readme.txt`、`post-image.sh`、`ext_board/*` 用于系统配置。
   - 额外的 package 可以直接被 Buildroot 框架使用。

   ## 常用构建命令

   1. Setup

   ```bash
   make O=../../output-ext -C buildroot/buildroot-2025.02 BR2_EXTERNAL=../../external my_qemu_x86_64_defconfig
   ```

   2. Build

   ```bash
   make O=../../output-ext -C buildroot/buildroot-2025.02 menuconfig  # 可修改内核版本
   make O=../../output-ext -C buildroot/buildroot-2025.02 all
   ```

   3. Configure

   ```bash
   make O=../../output-ext -C buildroot/buildroot-2025.02 linux-savedefconfig
   make O=../../output-ext -C buildroot/buildroot-2025.02 savedefconfig
   ```

   4. Help

   ```bash
   make O=../../output-ext -C buildroot/buildroot-2025.02 help
   ```

   5. Toolchain

   ```bash
   make O=../../output-ext -C buildroot/buildroot-2025.02 toolchain
   ```

   6. SDK

   ```bash
   make O=../../output-ext -C buildroot/buildroot-2025.02 sdk
   ```

   ### 关于 Linux 的 init 配置

   使用 BusyBox（默认）

   > BusyBox 的 init 程序会读取 `/etc/inittab`，默认的 `inittab` 存放在 `package/busybox/inittab`。默认会挂载必要的文件系统、运行 `/etc/init.d/rcS` 并启动 `getty` 提供登录提示。

   `/dev` 系统

   默认使用 `udev`（通常为 "devtmpfs only"）+ `devtmpfs`。

   内核可打开 `CONFIG_UEVENT_HELPER` 来支持 `/proc/sys/kernel/hotplug`。

   #### 内核配置

   在 Buildroot 中指定自定义内核配置文件：

   ```makefile
   BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE="$(BR2_EXTERNAL_MY_PATH)/board/ext_board/linux.config"
   ```

   ## 根文件系统（Initrd & initramfs）

   - **Initrd**：启动加载器将 initrd 读入内存并传递地址/大小给内核；常见用法为通过 `initrd` 参数加载临时根文件系统。
   - **initramfs**：cpio 格式的文件打包到内核映像中（由 `__initramfs_start` 与 `__initramfs_end` 标识）。

   默认方式无 initrd：内核直接挂载根设备，例如 `root=/dev/vda`。

   ## QEMU 外设配置示例

   ```bash
   DISK_ARGS="-drive file=nvme.img,if=none,id=D22 -device nvme,drive=D22,serial=1234"
   ```

   ## Buildroot 工具配置

   BusyBox 的 `lspci` 需要 `pciutils`。

   ## VFIO 支持（示例）

   Host 操作：

   ```bash
   # 解绑 nvme 驱动
   echo 0000:01:00.0 > /sys/bus/pci/drivers/nvme/unbind
   # 注册 vfio-pci 的 vendor/device id
   echo 2646 5027 > /sys/bus/pci/drivers/vfio-pci/new_id
   ```

   QEMU 启动示例：

   ```bash
   exec sudo env PATH="/home/code/buildroot/mybuildroot/output-ext/host/bin:${PATH}" gdb --args qemu-system-x86_64 -M pc \
     -kernel bzImage -drive file=rootfs.ext2,if=virtio,format=raw \
     -append "rootwait root=/dev/vda console=tty1 console=ttyS0" \
     -net nic,model=virtio -net user -device vfio-pci,host=0000:01:00.0,id=hostdev0 ${EXTRA_ARGS} "$@"
   ```

   VFIO 设备权限示例修复：

   ```bash
   sudo usermod -aG vfio $USER
   sudo chown root:vfio /dev/vfio/*
   sudo chmod 660 /dev/vfio/*
   # 临时修改权限
   sudo chmod 666 /dev/vfio/*
   ```

   ## 在 VSCode 中集成 GDB

   示例 `launch.json`（用于调试 host qemu）：

   ```json
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
         "miDebuggerPath": "/usr/bin/gdb",
         "setupCommands": [
           { "description": "Enable pretty-printing", "text": "-enable-pretty-printing", "ignoreFailures": true }
         ]
       }
     ]
   }
   ```

   ## 日志系统

   1. Linux kernel log: `dmesg`
   2. QEMU log: `-d guest_errors,unimp,pcall -D qemu.log`
   3. Linux app log: `printf`, `syslog`, `dmesg`, `journalctl`
   4. QEMU monitor: 在 QEMU 界面按 `Ctrl+Alt+2`，使用 `info` 子命令查看各种信息（`info pci`、`info qom-tree` 等）。

   ## Tips

   1. QEMU 编译失败（"fatal: this operation must be run in a work tree"）：

   ```bash
   meson subprojects download
   # or
   rm -rf subprojects/keycodemapdb
   git clone https://gitlab.com/qemu-project/keycodemapdb.git subprojects/keycodemapdb
   cd subprojects/keycodemapdb
   git checkout f5772a62ec52591ff6870b7e8ef32482371f22c6
   ```

   QEMU 需要从官网下载压缩包，不能直接用 `git clone` 来替代。

   2. 多用户环境下 ccache 冲突：

   ```bash
   export CCACHE_DIR="$HOME/.ccache_$USER"
   ```

   3. QEMU subprojects 下载错误示例：

   ```
   Download bilge-impl-0.2-rs...
   -> Diff file "subprojects/packagefiles/bilge-impl-1.63.0.patch" does not exist
   WARNING: Please check logs above as command failed in some subprojects which could have been left in conflict state: bilge-impl-0.2-rs
   ```

   ## 一键构建脚本 `b.sh`

   请参考 `b.sh` 的帮助文档。

   ## 其他扩展想法

   1. 扩展一个运行 ThreadX 的 BSP，包含定制内核和 rootfs，集成 QEMU 模拟器，提供完整开发环境。
   2. 扩展一个运行 RISC-V + Linux 的 BSP，包含定制内核和 rootfs，集成 QEMU 模拟器，提供完整开发环境。


