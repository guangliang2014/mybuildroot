--enable-virtfs

yum install -y libcap-devel
yum install -y libattr-devel

 ../qemu/qemu-9.2.0/configure --target-list=x86_64-softmmu --enable-virtfs

按照顺序进行打开
CONFIG_NET_9P=y
CONFIG_9P_FS=y
CONFIG_NET_9P_VIRTIO=y
CONFIG_9P_FS_POSIX_ACL=y
CONFIG_VIRTIO_PCI=y


    CONFIG_NET_9P=y
    CONFIG_NET_9P_VIRTIO=y
    CONFIG_9P_FS=y
    CONFIG_9P_FS_POSIX_ACL=y



-virtfs local,path=%HOST_SHARED_DIR%,mount_tag=tag,security_model=passthrough

sudo mount -t 9p -o trans=virtio hostshare /mnt/share


windows is not work well!!!

