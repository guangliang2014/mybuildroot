
/* DO NOT EDIT!  This is an autogenerated file.  See scripts/layoutrom.py. */
OUTPUT_FORMAT("elf32-i386")
OUTPUT_ARCH("i386")
SECTIONS
{
DebugOutputPort = 0x4f34 ;
MaxPCIBus = 0x448c ;
entry_pcibios32 = 0xca72 ;
PirAddr = 0x4488 ;
entry_apm16 = 0xc9ff ;
entry_apm32 = 0xca40 ;
acpi_pm1a_cnt = 0x4484 ;
.text.set_code_success 0x5130 : { *(.text.set_code_success) }
.text.get_global_offset 0x513a : { *(.text.get_global_offset) }
.text.qemu_debug_putc 0x5146 : { *(.text.qemu_debug_putc) }
.text.putsinglehex.constprop.0 0x515e : { *(.text.putsinglehex.constprop.0) }
.text.puthex.constprop.0 0x5178 : { *(.text.puthex.constprop.0) }
.text.pci_next 0x5212 : { *(.text.pci_next) }
.text.putuint.constprop.0 0x5286 : { *(.text.putuint.constprop.0) }
.text.__dprintf 0x52c5 : { *(.text.__dprintf) }
.rodata 0x5ae0 : { *(.rodata) }
.text.dump_regs 0x5549 : { *(.text.dump_regs) }
.text.__set_code_invalid 0x55b1 : { *(.text.__set_code_invalid) }
.text.handle_pcibios 0x55df : { *(.text.handle_pcibios) }
.text.handle_apm 0x5953 : { *(.text.handle_apm) }
.rodata.__func__.0 0x5bb0 : { *(.rodata.__func__.0) }
.rodata.__func__.1 0x5bc0 : { *(.rodata.__func__.1) }
.rodata.__func__.2 0x5bd0 : { *(.rodata.__func__.2) }
.rodata.__func__.3 0x5be0 : { *(.rodata.__func__.3) }
.rodata.__func__.4 0x5bf0 : { *(.rodata.__func__.4) }


        /* Discard regular data sections to force a link error if
         * code attempts to access data not marked with VAR16 (or other
         * appropriate macro)
         */
        /DISCARD/ : {
                *(.text*) *(.data*) *(.bss*) *(.rodata*)
                *(COMMON) *(.discard*) *(.eh_frame) *(.note*)
                }
}
