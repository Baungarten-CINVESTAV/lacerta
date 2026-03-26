OUTPUT_ARCH(riscv)
ENTRY(_start)

/* -------------------------------------------------------
 * Memory Map
 * ------------------------------------------------------- */
MEMORY
{
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 0xFA0
}

/* -------------------------------------------------------
 * Sections
 * ------------------------------------------------------- */
SECTIONS
{
    /* ---------------------------------------------------
     * Text / Code
     * --------------------------------------------------- */
    .text :
    {
        . = ALIGN(4);

        KEEP(*(.init))
        KEEP(*(.text.start))

        *(.text*)
        *(.rodata*)

        . = ALIGN(4);
    } > RAM


    /* ---------------------------------------------------
     * Small Data (gp-relative)
     * --------------------------------------------------- */
    .sdata :
    {
        . = ALIGN(4);
        __sdata_start = .;
        *(.sdata*)
        . = ALIGN(4);
        __sdata_end = .;
    } > RAM

    .sbss (NOLOAD) :
    {
        . = ALIGN(4);
        __sbss_start = .;
        *(.sbss*)
        . = ALIGN(4);
        __sbss_end = .;
    } > RAM


    /* ---------------------------------------------------
     * Regular Data
     * --------------------------------------------------- */
    .data :
    {
        . = ALIGN(4);
        __data_start = .;
        *(.data*)
        . = ALIGN(4);
        __data_end = .;
    } > RAM


    /* ---------------------------------------------------
     * BSS
     * --------------------------------------------------- */
    .bss (NOLOAD) :
    {
        . = ALIGN(4);
        __bss_start = .;
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end = .;
    } > RAM


    /* ---------------------------------------------------
     * Constructors / Destructors (for libc compatibility)
     * --------------------------------------------------- */
    .init_array :
    {
        . = ALIGN(4);
        __init_array_start = .;
        KEEP(*(.init_array*))
        __init_array_end = .;
    } > RAM

    .fini_array :
    {
        . = ALIGN(4);
        __fini_array_start = .;
        KEEP(*(.fini_array*))
        __fini_array_end = .;
    } > RAM


    /* ---------------------------------------------------
     * Global Pointer Definition
     * --------------------------------------------------- */

    /*
     * RISC-V ABI requires gp to point into the middle
     * of the small data region (±2048 bytes).
     */
    PROVIDE(__global_pointer$ = __sdata_start + 0x800);


    /* ---------------------------------------------------
     * Stack (Top of RAM)
     * --------------------------------------------------- */
    . = ORIGIN(RAM) + LENGTH(RAM);
    . = ALIGN(16);
    PROVIDE(_stack_top = .);
}