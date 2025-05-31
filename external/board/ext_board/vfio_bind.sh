#!/bin/bash

modprobe vfio-pci
echo 0000:01:00.0 > /sys/bus/pci/drivers/nvme/unbind 
echo 2646 5027 > /sys/bus/pci/drivers/vfio-pci/new_id

