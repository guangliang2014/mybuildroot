1, buildroot
   BR2_PACKAGE_HOST_QEMU_VIRTFS
   BR2_PACKAGE_HOST_RISCV_ISA_SIM
   --enable-virtfs

2, kernel
   按照顺序进行打开
    CONFIG_NET_9P=y
    CONFIG_9P_FS=y
    CONFIG_NET_9P_VIRTIO=y
    CONFIG_9P_FS_POSIX_ACL=y
    CONFIG_VIRTIO_PCI=y
3，host
yum install -y libcap-devel
yum install -y libattr-devel

4，使用
-virtfs local,path=%HOST_SHARED_DIR%,mount_tag=tag,security_model=passthrough
sudo mount -t 9p -o trans=virtio hostshare /mnt/share

5，windows is not work well!!!
