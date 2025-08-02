#!/bin/bash

# Gen by Lingma @20250802

# 默认参数
BUILDROOT_DIR="buildroot/buildroot-2025.02"

# 显示帮助信息
show_help() {
    echo "Usage: $0 <external_path> <command> [defconfig]"
    echo "Commands:"
    echo "  init                  - Initialize Buildroot environment"
    echo "  setup                 - Setup defconfig (requires defconfig name as third argument)"
    echo "  menuconfig            - Configure Buildroot"
    echo "  linux-menuconfig      - Configure Linux kernel"
    echo "  all                   - Build all"
    echo "  linux-rebuild         - Rebuild Linux kernel"
    echo "  qemu-rebuild          - Rebuild QEMU"
    echo "  host-qemu-rebuild     - Rebuild host QEMU"
    echo "  savedefconfig         - Save Buildroot and Linux defconfig"
    echo "  linux-savedefconfig   - Save Linux defconfig only"
    echo "  toolchain             - Build toolchain"
    echo "  sdk                   - Build SDK"
    echo "  help                  - Show Buildroot help"
    echo ""
    echo "Examples:"
    echo "  $0 minisys setup minisys my_qemu_x86_64_defconfig"
    echo "  $0 minisys all"
}

# 检查参数数量
if [ $# -lt 2 ]; then
    echo "Error: Invalid number of arguments"
    show_help
    exit 1
fi

EXTERNAL_ARG="../../$1"
COMMAND="$2"
DEFCONFIG="$3"

# 检查EXTERNAL_ARG目录是否存在
if [ ! -d "$1" ]; then
    echo "Error: External directory '${EXTERNAL_ARG}' does not exist"
    exit 1
fi

# 根据external路径动态生成输出目录名称
EXTERNAL_BASE=$(basename "${EXTERNAL_ARG}")
OUTPUT_DIR="../../output-${EXTERNAL_BASE}"

# 构建基础命令
BASE_CMD="make O=${OUTPUT_DIR} -C ${BUILDROOT_DIR}"

# 执行相应命令
case "${COMMAND}" in
    init)
        git submodule init
        git submodule update
        ;;

    setup)
        if [ -z "${DEFCONFIG}" ]; then
            echo "Error: Defconfig name is required for setup command"
            show_help
            exit 1
        fi

        echo ${BASE_CMD} BR2_EXTERNAL=${EXTERNAL_ARG}  ${DEFCONFIG}
        ${BASE_CMD} BR2_EXTERNAL=${EXTERNAL_ARG}  ${DEFCONFIG}
        ;;
    menuconfig)
        echo ${BASE_CMD} menuconfig
        ${BASE_CMD} menuconfig
        ;;
    linux-menuconfig)
        echo ${BASE_CMD} linux-menuconfig
        ${BASE_CMD} linux-menuconfig
        ;;
    all)
        echo ${BASE_CMD} all
        ${BASE_CMD} all
        ;;
    linux-rebuild)
        echo ${BASE_CMD} linux-dirclean linux-rebuild
        ${BASE_CMD} linux-dirclean linux-rebuild
        ;;
    qemu-rebuild)
        echo ${BASE_CMD} qemu-dirclean qemu-rebuild
        ${BASE_CMD} qemu-dirclean qemu-rebuild
        ;;
    host-qemu-rebuild)
        echo ${BASE_CMD} host-qemu-dirclean host-qemu-rebuild
        ${BASE_CMD} host-qemu-dirclean host-qemu-rebuild
        ;;
    savedefconfig)
        echo ${BASE_CMD} savedefconfig
        ${BASE_CMD} savedefconfig
        ;;
    linux-savedefconfig)
        echo ${BASE_CMD} linux-savedefconfig
        ${BASE_CMD} savedefconfig
        ;;
    toolchain)
        echo ${BASE_CMD} toolchain
        ${BASE_CMD} toolchain
        ;;
    sdk)
        echo ${BASE_CMD} sdk
        ${BASE_CMD} sdk
        ;;
    help)
        ${BASE_CMD} help
        ;;
    *)
        echo "Error: Unknown command '${COMMAND}'"
        show_help
        exit 1
        ;;
esac