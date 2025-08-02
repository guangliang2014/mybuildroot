/* SPDX-License-Identifier: BSD-3-Clause
 *
 * Copyright (C) 2018-2019 Arm Ltd.
 * Author: Vincent Stehlé <vincent.stehle@arm.com>
 *
 * This is inspired from Linux Documentation/vfio.txt
 */

#include "vfio.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <err.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <linux/vfio.h>
#include <assert.h>
#include <stdint.h>
#include <unistd.h>
#include "cmdline.h"


#define PCI_CAP_PTR_OFFSET   0x34
#define PCI_CONFIG_SPACE_SIZE 256   // 标准PCI配置空间
#define PCI_EXT_CAP_START    0x100
#define PCI_EXT_CONFIG_SPACE_SIZE 4096 // 典型PCI扩展配置空间


// 解析并打印 MSI-X Capability 信息
void parse_print_msix_capability(const uint8_t *config, uint8_t msix_offset)
{
    if (config[msix_offset] != 0x11) {
        printf("Not a MSI-X capability at offset 0x%02x\n", msix_offset);
        return;
    }

    // Table Offset
    uint32_t table = *(uint32_t *)(config + msix_offset + 2);
    uint8_t table_bir = table & 0x7;
    uint32_t table_offset = table & ~0x7;

    // PBA Offset
    uint32_t pba = *(uint32_t *)(config + msix_offset + 6);
    uint8_t pba_bir = pba & 0x7;
    uint32_t pba_offset = pba & ~0x7;

    // Control
    uint16_t control = *(uint16_t *)(config + msix_offset + 10);
    uint16_t table_size = (control & 0x07FF) + 1; // 11 bits, value is N-1

    printf("MSI-X Capability @ 0x%02x:\n", msix_offset);
    printf("  Table: BAR %u, Offset 0x%x\n", table_bir, table_offset);
    printf("  PBA:   BAR %u, Offset 0x%x\n", pba_bir, pba_offset);
    printf("  Table Size: %u\n", table_size);
    printf("  Control: 0x%04x\n", control);
    printf("    MSI-X Enable: %s\n", (control & (1 << 15)) ? "Yes" : "No");
    printf("    Function Mask: %s\n", (control & (1 << 14)) ? "Yes" : "No");
}


// 遍历标准PCI Capabilities
void scan_pci_capabilities(const uint8_t *config)
{
    uint8_t cap_ptr = config[PCI_CAP_PTR_OFFSET];
    printf("Standard PCI Capabilities:\n");
    while (cap_ptr >= 0x40 && cap_ptr <= 0xFF) {
        uint8_t cap_id = config[cap_ptr];
        uint8_t next_ptr = config[cap_ptr + 1];
        printf("  Capability ID: 0x%02x at offset 0x%02x, next: 0x%02x\n", cap_id, cap_ptr, next_ptr);
        if (next_ptr == 0 || next_ptr == cap_ptr) break;
        cap_ptr = next_ptr;
    }
}

// 遍历PCI Extended Capabilities
void scan_pci_ext_capabilities(const uint8_t *config, size_t config_len)
{
    uint16_t ext_ptr = PCI_EXT_CAP_START;
    printf("PCI Extended Capabilities:\n");
    while (ext_ptr + 4 <= config_len) {
        uint16_t ext_cap_id = *(uint16_t *)(config + ext_ptr);
        uint16_t next_ext_ptr = (*(uint16_t *)(config + ext_ptr + 2)) >> 4; // next pointer is high 12 bits of offset
        if (ext_cap_id == 0) break;
        printf("  Ext Cap ID: 0x%04x at offset 0x%03x, next: 0x%03x\n",
               ext_cap_id, ext_ptr, next_ext_ptr);

		if (ext_cap_id == 0x11) {
    		parse_print_msix_capability(config, ext_ptr);
		}

        if (next_ext_ptr == 0 || next_ext_ptr == ext_ptr) break;
        ext_ptr = next_ext_ptr;
    }
}


// mmap VFIO config region
uint8_t *mmap_vfio_config(int device_fd, uint64_t offset, uint64_t size)
{
    void *addr = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, device_fd, offset);
    if (addr == MAP_FAILED) {
        perror("mmap vfio config region");
        return NULL;
    }
    return (uint8_t *)addr;
}




void vfio_setup(struct vfio *v, const struct cmdline *cl)
{
	int s;
	struct vfio_group_status group_status = {
		.argsz = sizeof(group_status),
	};
	struct vfio_iommu_type1_info iommu_info = {
		.argsz = sizeof(iommu_info),
	};
	struct vfio_device_info device_info = {
		.argsz = sizeof(device_info),
	};

	assert(v);
	assert(cl);

	memset(v, 0, sizeof(*v));

	/* Create a new container */
	v->container_fd = open("/dev/vfio/vfio", O_RDWR);
	if (v->container_fd == -1)
		err(1, "open /dev/vfio/vfio");

	if (ioctl(v->container_fd, VFIO_GET_API_VERSION) != VFIO_API_VERSION)
		err(1, "Unknown API version");

	if (!ioctl(v->container_fd, VFIO_CHECK_EXTENSION, VFIO_TYPE1_IOMMU))
		err(1, "Doesn't support the IOMMU driver we want");

	/* Open the group */
	v->group_fd = open(cl->vfio_group, O_RDWR);
	if (v->group_fd == -1)
		err(1, "open %s", cl->vfio_group);

	/* Test the group is viable and available */
	s = ioctl(v->group_fd, VFIO_GROUP_GET_STATUS, &group_status);
	if (s)
		err(1, "get group status: %d", s);

	if (!(group_status.flags & VFIO_GROUP_FLAGS_VIABLE))
		errx(1, "Group is not viable");

	/* Add the group to the container */
	s = ioctl(v->group_fd, VFIO_GROUP_SET_CONTAINER, &v->container_fd);
	if (s)
		err(1, "set container: %d", s);

	/* Enable the IOMMU model we want */
	s = ioctl(v->container_fd, VFIO_SET_IOMMU, VFIO_TYPE1_IOMMU);
	if (s)
		err(1, "set iommu: %d", s);

	/* Get addition IOMMU info */
	s = ioctl(v->container_fd, VFIO_IOMMU_GET_INFO, &iommu_info);
	if (s)
		err(1, "get iommu info: %d", s);

	if (iommu_info.flags & VFIO_IOMMU_INFO_PGSIZES)
		printf("Supported page sizes bitmap: %#llx\n",
				iommu_info.iova_pgsizes);

	/* Get a file descriptor for the device */
	v->device_fd = ioctl(v->group_fd, VFIO_GROUP_GET_DEVICE_FD,
				cl->device);
	if (v->device_fd <= 0)
		err(1, "get device fd: %d", v->device_fd);

	/* Test and setup the device */
	s = ioctl(v->device_fd, VFIO_DEVICE_GET_INFO, &device_info);
	if (s)
		err(1, "get device info: %d", s);

	printf("num_regions: %d, num_irqs: %d\n", device_info.num_regions,
		device_info.num_irqs);

	if (!(device_info.flags & VFIO_DEVICE_FLAGS_PCI))
		errx(1, "not a pci device");

	// Reset device if supported
	if (device_info.flags & VFIO_DEVICE_FLAGS_RESET) {
		s = ioctl(v->device_fd, VFIO_DEVICE_RESET);
		if (s)
			err(1, "reset device: %d", s);
	}

	// Config region
	v->config_region = (struct vfio_region_info){
		.argsz = sizeof(v->bar0_region),
		.index = VFIO_PCI_CONFIG_REGION_INDEX,
	};

	s = ioctl(v->device_fd, VFIO_DEVICE_GET_REGION_INFO, &v->config_region);
	if (s)
		err(1, "get config region info: %d", s);

	if (!(v->config_region.flags & VFIO_REGION_INFO_FLAG_READ))
		errx(1, "config region not readable");

	if (!(v->config_region.flags & VFIO_REGION_INFO_FLAG_WRITE))
		errx(1, "config region not writable");

	printf("Config size: %lld, offset: %#llx\n", v->config_region.size,
		v->config_region.offset);
	
	printf("begin test vfio cfg:\n");

	// config_region 已通过 VFIO_DEVICE_GET_REGION_INFO ioctl 获取
	uint8_t *config_map = mmap_vfio_config(v->device_fd, v->config_region.offset, v->config_region.size);
	if (!config_map) {
    	exit(1);
	}

	// 之后可用 config_map 访问 PCI 配置空间内容
	scan_pci_capabilities(config_map);
	scan_pci_ext_capabilities(config_map, v->config_region.size);

	// 使用完毕后释放
	munmap(config_map, v->config_region.size);
	printf("end test vfio cfg.\n");
}

// Setup a DMA mapping
void vfio_map_dma(struct vfio *v, void *bufs, size_t size, uint64_t iova)
{
	int s;

	assert(v);
	assert(bufs);
	assert(size);
	assert(iova);

	v->dma_map = (struct vfio_iommu_type1_dma_map){
		.argsz = sizeof(v->dma_map),
		.flags = VFIO_DMA_MAP_FLAG_READ | VFIO_DMA_MAP_FLAG_WRITE,
		.iova = iova, /* Starting address from device view */
		.size = size,
		.vaddr = (__u64)bufs,
	};

	s = ioctl(v->container_fd, VFIO_IOMMU_MAP_DMA, &v->dma_map);
	if (s)
		err(1, "map dma: %d", s);

	printf("Buffers @%p, size: %ld, iova: %#lx\n", bufs, size, iova);
}

void *vfio_map_bar0(struct vfio *v)
{
	int s;

	assert(v);
	assert(!v->bar0);

	v->bar0_region = (struct vfio_region_info){
		.argsz = sizeof(v->bar0_region),
		.index = VFIO_PCI_BAR0_REGION_INDEX,
	};

	s = ioctl(v->device_fd, VFIO_DEVICE_GET_REGION_INFO, &v->bar0_region);
	if (s)
		err(1, "get bar0 region info: %d", s);

	if (!(v->bar0_region.flags & VFIO_REGION_INFO_FLAG_READ))
		errx(1, "bar0 region not readable");

	if (!(v->bar0_region.flags & VFIO_REGION_INFO_FLAG_WRITE))
		errx(1, "bar0 region not writable");

	if (!(v->bar0_region.flags & VFIO_REGION_INFO_FLAG_MMAP))
		errx(1, "bar0 region not mmap'able");

	v->bar0 = mmap(0, v->bar0_region.size, PROT_READ | PROT_WRITE,
			MAP_SHARED, v->device_fd, v->bar0_region.offset);
	if (v->bar0 == MAP_FAILED)
		err(1, "mmap bar0 failed");

	printf("BAR0 @%p, size: %lld, offset: %#llx\n", v->bar0,
		v->bar0_region.size, v->bar0_region.offset);
	return v->bar0;
}

uint8_t vfio_read_config(struct vfio *v, unsigned int off)
{
	ssize_t s;
	uint8_t r;
	off_t o;

	assert(v);

	o = v->config_region.offset + off;
	s = pread(v->device_fd, &r, 1, o);
	if (s != 1)
		err(1, "config read: %ld", s);

	return r;
}

void vfio_write_config(struct vfio *v, unsigned int off, uint8_t val)
{
	ssize_t s;
	off_t o;

	assert(v);

	o = v->config_region.offset + off;
	s = pwrite(v->device_fd, &val, 1, o);
	if (s != 1)
		err(1, "config write: %ld", s);
}

void vfio_teardown(struct vfio *v)
{
	int s;
	struct vfio_iommu_type1_dma_unmap dma_unmap = {
		.argsz = sizeof(dma_unmap),
		.flags = 0,
		.iova  = v->dma_map.iova,
		.size  = v->dma_map.size,
	};

	assert(v);

	if (v->bar0) {
		s = munmap(v->bar0, v->bar0_region.size);
		if (s)
			warn("munmap bar0: %d", s);
	}

	if (v->dma_map.size) {
		s = ioctl(v->container_fd, VFIO_IOMMU_UNMAP_DMA, &dma_unmap);
		if (s)
			warn("unmap dma: %d", s);
	}

	s = close(v->device_fd);
	if (s)
		warn("close device: %d", s);

	s = ioctl(v->group_fd, VFIO_GROUP_UNSET_CONTAINER);
	if (s)
		warn("unset container: %d", s);

	s = close(v->group_fd);
	if (s)
		warn("close group: %d", s);

	s = close(v->container_fd);
	if (s)
		warn("close container: %d", s);

#ifndef NDEBUG
	memset(v, 0, sizeof(*v));
#endif
}
