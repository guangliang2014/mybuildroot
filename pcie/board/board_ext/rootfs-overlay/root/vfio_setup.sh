#!/bin/sh
# install vfio-pci
modprobe vfio-pci
# unbind from driver_test
echo -n 0000:01:00.0 > /sys/bus/pci/devices/0000:01:00.0/driver/unbind
echo 1b36 0010 > /sys/bus/pci/drivers/vfio-pci/new_id