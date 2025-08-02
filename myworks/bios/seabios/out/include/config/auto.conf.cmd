deps_config := \
	vgasrc/Kconfig \
	/home/code/buildroot/mybuildroot/qemu/qemu-9.2.0/roms/seabios/src/Kconfig

include/config/auto.conf: \
	$(deps_config)


$(deps_config): ;
