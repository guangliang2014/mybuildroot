#!/bin/bash

QEMU_BOARD_DIR="$(dirname $0)"
#DEFCONFIG_NAME="$(basename $2)"
DEFCONFIG_NAME="qemu_x86_64_defconfig"
README_FILES="${QEMU_BOARD_DIR}/readme.txt"
START_QEMU_SCRIPT="${BINARIES_DIR}/start-qemu.sh"

if [[ "${DEFCONFIG_NAME}" =~ ^"qemu_*" ]]; then
    # Not a Qemu defconfig, can't test.
    exit 0
fi

# Search for "# qemu_*_defconfig" tag in all readme.txt files.
# Qemu command line on multilines using back slash are accepted.
# shellcheck disable=SC2086 # glob over each readme file
QEMU_CMD_LINE="$(sed -r ':a; /\\$/N; s/\\\n//; s/\t/ /; ta; /# '"${DEFCONFIG_NAME}"'$/!d; s/#.*//' ${README_FILES})"

if [ -z "${QEMU_CMD_LINE}" ]; then
    # No Qemu cmd line found, can't test.
    exit 0
fi

# Remove output/images path since the script will be in
# the same directory as the kernel and the rootfs images.
QEMU_CMD_LINE="${QEMU_CMD_LINE//output\/images\//}"

# Remove -serial stdio if present, keep it as default args
DEFAULT_ARGS="$(sed -r -e '/-serial stdio/!d; s/.*(-serial stdio).*/\1/' <<<"${QEMU_CMD_LINE}")"
QEMU_CMD_LINE="${QEMU_CMD_LINE//-serial stdio/}"

# Remove any string before qemu-system-*
QEMU_CMD_LINE="$(sed -r -e 's/^.*(qemu-system-)/\1/' <<<"${QEMU_CMD_LINE}")"

# Disable graphical output and redirect serial I/Os to console
case ${DEFCONFIG_NAME} in
  (qemu_sh4eb_r2d_defconfig|qemu_sh4_r2d_defconfig)
    # Special case for SH4
    SERIAL_ARGS="-serial stdio -display none"
    ;;
  (*)
    SERIAL_ARGS="-nographic"
    ;;
esac

sed -e "s|@SERIAL_ARGS@|${SERIAL_ARGS}|g" \
    -e "s|@DEFAULT_ARGS@|${DEFAULT_ARGS}|g" \
    -e "s|@QEMU_CMD_LINE@|${QEMU_CMD_LINE}|g" \
    -e "s|@HOST_DIR@|${HOST_DIR}|g" \
    <"${QEMU_BOARD_DIR}/start-qemu.sh.in" \
    >"${START_QEMU_SCRIPT}"
chmod +x "${START_QEMU_SCRIPT}"
