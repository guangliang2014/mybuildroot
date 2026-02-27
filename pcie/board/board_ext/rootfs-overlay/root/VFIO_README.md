VFIO passthrough helper scripts
================================

Files
- `vfio_bind.sh` - bind / unbind / restore a PCI device to `vfio-pci` on host.
- `start_guest_with_vfio.sh` - helper to start a QEMU guest with `-device vfio-pci,host=...`.

Quick workflow
1. Identify the host device BDF (example `0000:01:00.0`):

   sudo lspci -nn | grep -i nvme

2. Bind the device to vfio-pci on the host (this will unbind its current driver and record it):

   sudo ./vfio_bind.sh bind 0000:01:00.0

3. Start a guest and pass the device through:

   ./start_guest_with_vfio.sh 0000:01:00.0 -- [other qemu args like -kernel, -drive ...]

4. Inside guest, verify with `dmesg` and `ls /dev/nvme*` (ensure guest has nvme driver):

   dmesg | tail -n 50
   ls -l /dev/nvme*

5. To restore the device back to original driver on host:

   sudo ./vfio_bind.sh restore 0000:01:00.0

Notes and warnings
- Ensure host IOMMU is enabled (kernel boot option `intel_iommu=on` or `iommu=pt`) and `vfio-pci` module is available.
- Do not bind devices that are actively used by the host (mounted filesystems, active block devices, etc.). Unmount and stop services first.
- Passing a physical device to a guest removes it from host control; back up any data first.
