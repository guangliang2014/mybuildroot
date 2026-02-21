################################################################################
# edu-test Buildroot package (kitos)
################################################################################

EDU_TEST_VERSION = 1.0
# Use local site (sources included in the external)
EDU_TEST_SITE = $(BR2_EXTERNAL_KITOS_PATH)/package/edu-test
EDU_TEST_SITE_METHOD = local
EDU_TEST_SOURCE = test.c
EDU_TEST_LICENSE = MIT

EDU_TEST_DEPENDENCIES =

define EDU_TEST_BUILD_CMDS
	# compile from the package build directory (rsynced by Buildroot)
	$(TARGET_CC) $(TARGET_CFLAGS) -o $(@D)/test-edu $(@D)/test.c $(TARGET_LDFLAGS)
endef

define EDU_TEST_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/test-edu $(TARGET_DIR)/usr/bin/test-edu
endef

$(eval $(generic-package))
