    .section .text.start
    .globl _start

    .extern _stack_top
    .extern __global_pointer$
    .extern __bss_start
    .extern __bss_end
    .extern main

_start:
    /* Initialize global pointer first (norelax prevents gp-relative self-reference) */
    .option push
    .option norelax
    la      gp, __global_pointer$
    .option pop

    /* Initialize stack pointer (la may now use gp-relative if in range) */
    la      sp, _stack_top

    /* Clear .bss */
    la      t0, __bss_start
    la      t1, __bss_end

bss_loop:
    bgeu    t0, t1, bss_done
    sw      zero, 0(t0)
    addi    t0, t0, 4
    j       bss_loop

bss_done:

    /* Call main */
    call    main

1:
    j       1b