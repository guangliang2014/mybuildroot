
echo 0000:00:03.0 > /sys/bus/pci/drivers/nvme/unbind
modprobe vfio-pci
echo 1b36 0010 > /sys/bus/pci/drivers/vfio-pci/new_id
