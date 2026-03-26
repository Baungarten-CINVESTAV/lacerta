"""
program_template.py

Holds the bare-metal RISC-V source templates (linker script, crt0, delay,
and the debug-test C file) and runs the build pipeline that mirrors the
Makefile steps 1 / 3 / 4 / 5 / 6:

  Step 1  –  GCC  → .elf
  Step 3  –  objcopy  → .bin  (raw binary)
  Step 4  –  Python   → .mem  (one hex byte per line, little-endian)
  Step 5  –  Python   → _be.hex  (big-endian per 32-bit word)
  Step 6  –  objdump  → .dump  (disassembly listing)

All output files are written to  output/<canvas_name>/
and are named after the canvas (e.g. my_canvas.elf, my_canvas_be.hex …).
"""

import os
import sys
import subprocess

# Suppress console windows on Windows for all child processes
_POPEN_FLAGS = {"creationflags": subprocess.CREATE_NO_WINDOW} if sys.platform == "win32" else {}

# ---------------------------------------------------------------------------
# Toolchain resolution
# ---------------------------------------------------------------------------

_REPO_ROOT = os.path.dirname(              # lacerta_hmi/
    os.path.dirname(                       # tools/
        os.path.dirname(                   # tools/scripts/
            os.path.dirname(               # tools/scripts/python/
                os.path.abspath(__file__)  # tools/scripts/python/program_template.py
            )
        )
    )
)


def _toolchain_exe(name: str) -> str:
    """Return path to a riscv-none-elf-* binary.

    Checks the local xpacks install first, then falls back to PATH.
    """
    local = os.path.join(
        _REPO_ROOT, "tools", "xpacks",
        "xpack-dev-tools-riscv-none-elf-gcc",
        ".content", "bin",
        name + (".exe" if sys.platform == "win32" else ""),
    )
    return local if os.path.isfile(local) else name


# ---------------------------------------------------------------------------
# Source-file templates
# ---------------------------------------------------------------------------

LINKER_LD = """\
OUTPUT_ARCH(riscv)
ENTRY(_start)

/* -------------------------------------------------------
 * Memory Map
 * ------------------------------------------------------- */
MEMORY
{
    RAM (rwx) : ORIGIN = 0x20000000, LENGTH = 0xFA0
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
     * RISC-V ABI: gp points to middle of small data (±2048 bytes)
     * --------------------------------------------------- */
    PROVIDE(__global_pointer$ = __sdata_start + 0x800);


    /* ---------------------------------------------------
     * Stack (Top of RAM)
     * --------------------------------------------------- */
    . = ORIGIN(RAM) + LENGTH(RAM);
    . = ALIGN(16);
    PROVIDE(_stack_top = .);
}
"""

CRT0_S = """\
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
"""

DELAY_S = """\
.global delay

############################################################
# delay
# Software stall: N = (0.05 * 50_000_000) / (2 * 8) = 156250
############################################################
delay:
    li      t0, 5
1:
    addi    t0, t0, -1
    bnez    t0, 1b
    ret
"""

DEBUG_TEST_TEMPLATE_C = """\
#include <stdint.h>

#define REG_VALUE      0x8000002C
#define REG_TYPE       0x80000030
#define REG_WIDTH      0x80000034
#define REG_HEIGHT     0x80000038
#define REG_ADDR       0x8000003C
#define REG_MASK_ADDR  0x80000040

static inline uint32_t read_mem(uint32_t addr)
{
    volatile uint32_t *ptr = (volatile uint32_t *)addr;
    return *ptr;
}

static inline void write_mem(uint32_t addr, uint32_t val)
{
    volatile uint32_t *ptr = (volatile uint32_t *)addr;
    *ptr = val;
}

/* delay implemented in delay.S */
void delay(void);

/* ------------------------------------------------------------
 * Generic object refresh
 * ------------------------------------------------------------ */
static void refresh_object(uint32_t type,
                           uint32_t value,
                           uint32_t width,
                           uint32_t height,
                           uint32_t start_addr,
                           uint32_t mask_addr)
{
    write_mem(REG_TYPE, type);
    write_mem(REG_WIDTH, width);
    write_mem(REG_HEIGHT, height);
    write_mem(REG_ADDR, start_addr);
    write_mem(REG_MASK_ADDR, mask_addr);
    write_mem(REG_VALUE, value);
}

/* ------------------------------------------------------------
 * Digit (mask depends on value)
 * ------------------------------------------------------------ */
static void refresh_digit(uint32_t value,
                          uint32_t width,
                          uint32_t height,
                          uint32_t start_addr,
                          uint32_t mask_base)
{
    uint32_t mask_addr = mask_base + value * width * height;

    refresh_object(
        4,              /* type */
        0,              /* value not used for digit */
        width,
        height,
        start_addr,
        mask_addr
    );
}

/* ------------------------------------------------------------
 * Graph
 * ------------------------------------------------------------ */
static void refresh_graph(uint32_t value,
                          uint32_t width,
                          uint32_t height,
                          uint32_t start_addr)
{
    refresh_object(
        3,
        value,
        width,
        height,
        start_addr,
        0xFFFFFFFF
    );
}

/* ------------------------------------------------------------
 * Vertical bar
 * ------------------------------------------------------------ */
static void refresh_vertical(uint32_t value,
                             uint32_t width,
                             uint32_t height,
                             uint32_t start_addr)
{
    refresh_object(
        2,
        value,
        width,
        height,
        start_addr,
        0xFFFFFFFF
    );
}

/* ------------------------------------------------------------
 * Horizontal bar
 * ------------------------------------------------------------ */
static void refresh_horizontal(uint32_t value,
                               uint32_t width,
                               uint32_t height,
                               uint32_t start_addr)
{
    refresh_object(
        1,
        value,
        width,
        height,
        start_addr,
        0xFFFFFFFF
    );
}

/* ------------------------------------------------------------
 * Main
 * ------------------------------------------------------------ */
int main(void)
{
    uint32_t counter = 0;
    uint32_t counter_7seg = 0;

    while (1) {

        if (counter > 100)
            counter = 0;

        if (counter_7seg > 9)
            counter_7seg = 0;

        // INSERT ELEMENTS HERE

        // END OF ELEMENTS

        counter += 10;
        counter_7seg += 1;
    }

    return 0;
}
"""


# ---------------------------------------------------------------------------
# Code generation
# ---------------------------------------------------------------------------

# Supported obj_type → refresh function name
_REFRESH_FN = {
    "linear_v": "refresh_vertical",
    "linear_h": "refresh_horizontal",
    "graph": "refresh_graph",
    "seven_seg": "refresh_digit"
}


def _generate_elements(items: list) -> str:
    """Return the C lines to insert between INSERT / END markers.

    Each supported item produces:
        refresh_<fn>(counter, <width>, <height>, 640 * <y> + <x>);
        while (read_mem(0x80000000) == 0) {}
        while (read_mem(0x80000000) == 1) {}
        delay();

    Items whose obj_type is not in _REFRESH_FN are silently skipped.
    """
    lines = []
    for item in items:
        fn = _REFRESH_FN.get(item["obj_type"])
        if fn is None:
            continue
        w  = int(item["width"])
        h  = int(item["height"])
        x  = int(item["x"])
        y  = int(item["y"])
        if (fn == "refresh_digit"):
            lines += [
                f"        {fn}(counter_7seg, {w}, {h}, 640 * {y} + {x}, 640 * 480);",
                f"        while (read_mem(0x80000000) == 0) {{}}",
                f"        while (read_mem(0x80000000) == 1) {{}}",
                f"        delay();",
                "",
            ]
        else:
            lines += [
                f"        {fn}(counter, {w}, {h}, 640 * {y} + {x});",
                f"        while (read_mem(0x80000000) == 0) {{}}",
                f"        while (read_mem(0x80000000) == 1) {{}}",
                f"        delay();",
                "",
            ]
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Build pipeline
# ---------------------------------------------------------------------------

def build(canvas_name: str, items: list = None, output_dir: str = None, delay_count: int = 5, gcc_exe: str = None, log_fn=None) -> tuple[bool, str]:
    """Compile the debug-test template for *canvas_name*.

    *items* is a list of dicts with keys: obj_type, width, height, x, y.
    Supported obj_type values: "linear_v", "linear_h".
    Unsupported types are skipped without error.

    Steps run:
      1  gcc        source files  →  <canvas_name>.elf
      3  objcopy    .elf          →  <canvas_name>.bin   (raw binary)
      4  Python     .bin          →  <canvas_name>.mem   (LE, 1 byte/line)
      5  Python     .mem          →  <canvas_name>_be.hex  (BE per 32-bit word)
      6  objdump    .elf          →  <canvas_name>.dump  (disassembly)

    Returns (success, message).
    """
    if output_dir is None:
        output_dir = os.path.join(_REPO_ROOT, "output", canvas_name)
    os.makedirs(output_dir, exist_ok=True)

    # ── generate C source with items inserted ──────────────────────────────
    element_code = _generate_elements(items or [])
    c_source = DEBUG_TEST_TEMPLATE_C.replace(
        "        // INSERT ELEMENTS HERE",
        "        // INSERT ELEMENTS HERE\n" + element_code,
    )

    # ── write template source files ────────────────────────────────────────
    c_file    = os.path.join(output_dir, f"{canvas_name}.c")
    crt0_file = os.path.join(output_dir, "crt0.S")
    delay_file = os.path.join(output_dir, "delay.S")
    ld_file   = os.path.join(output_dir, "linker.ld")

    with open(c_file,     "w") as f: f.write(c_source)
    delay_source = DELAY_S.replace("    li      t0, 5\n",
                                    f"    li      t0, {delay_count}\n")

    with open(crt0_file,  "w") as f: f.write(CRT0_S)
    with open(delay_file, "w") as f: f.write(delay_source)
    with open(ld_file,    "w") as f: f.write(LINKER_LD)

    # ── output paths ───────────────────────────────────────────────────────
    elf    = os.path.join(output_dir, f"{canvas_name}.elf")
    bin_   = os.path.join(output_dir, f"{canvas_name}.bin")
    mem    = os.path.join(output_dir, f"{canvas_name}.mem")
    be_hex = os.path.join(output_dir, f"{canvas_name}_be.hex")
    dump   = os.path.join(output_dir, f"{canvas_name}.dump")

    gcc     = _toolchain_exe("riscv-none-elf-gcc")
    objcopy = _toolchain_exe("riscv-none-elf-objcopy")
    objdump = _toolchain_exe("riscv-none-elf-objdump")

    # If a specific gcc executable was provided (e.g. from GUI settings), derive
    # the bin directory from it so objcopy/objdump are found alongside it.
    if gcc_exe and os.path.isfile(gcc_exe):
        _bin_dir = os.path.dirname(os.path.abspath(gcc_exe))
        _ext = ".exe" if sys.platform == "win32" else ""

        def _sibling(name: str) -> str:
            candidate = os.path.join(_bin_dir, name + _ext)
            return candidate if os.path.isfile(candidate) else name

        gcc     = _sibling("riscv-none-elf-gcc")
        objcopy = _sibling("riscv-none-elf-objcopy")
        objdump = _sibling("riscv-none-elf-objdump")

    # ── step 1: compile → ELF ─────────────────────────────────────────────
    cmd = [
        gcc,
        "-march=rv32i", "-mabi=ilp32", "-nostartfiles", "-O2",
        "-T", ld_file,
        "-o", elf,
        crt0_file, delay_file, c_file,
    ]
    if log_fn:
        log_fn(f"[gcc] {' '.join(cmd)}", "#888888")
    proc = subprocess.Popen(
        cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        text=True, **_POPEN_FLAGS
    )
    gcc_output_lines = []
    for line in proc.stdout:
        line = line.rstrip()
        if line:
            gcc_output_lines.append(line)
            if log_fn:
                log_fn(f"[gcc] {line}", "#e5c07b")
    proc.wait()
    if proc.returncode != 0:
        return False, f"[step 1] Compile error:\n" + "\n".join(gcc_output_lines)
    if log_fn:
        log_fn("[gcc] Compile OK → " + os.path.basename(elf), "#98c379")

    # ── step 3: ELF → raw binary ──────────────────────────────────────────
    cmd = [objcopy, "-O", "binary", elf, bin_]
    r = subprocess.run(cmd, capture_output=True, text=True, **_POPEN_FLAGS)
    if r.returncode != 0:
        return False, f"[step 3] objcopy error:\n{r.stderr.strip()}"
    if log_fn:
        log_fn(f"[objcopy] → {os.path.basename(bin_)}", "#98c379")

    # ── step 4: binary → byte-per-line .mem (little-endian) ───────────────
    with open(bin_, "rb") as f:
        raw = f.read()
    with open(mem, "w") as f:
        for byte in raw:
            f.write(f"{byte:02X}\n")

    # ── step 5: .mem → _be.hex (big-endian per 32-bit word) ───────────────
    lines = open(mem).read().splitlines()
    lines = [l for l in lines if l.strip()]
    if len(lines) % 4 != 0:
        return False, (
            f"[step 5] Binary size ({len(lines)} bytes) is not a multiple of 4"
        )
    be_lines = []
    for i in range(0, len(lines), 4):
        be_lines.extend(reversed(lines[i:i + 4]))
    with open(be_hex, "w") as f:
        for b in be_lines:
            f.write(b.upper() + "\n")

    # ── step 6: ELF → disassembly dump ────────────────────────────────────
    cmd = [objdump, "-d", elf]
    r = subprocess.run(cmd, capture_output=True, text=True, **_POPEN_FLAGS)
    if r.returncode != 0:
        return False, f"[step 6] objdump error:\n{r.stderr.strip()}"
    with open(dump, "w") as f:
        f.write(r.stdout)
    if log_fn:
        log_fn(f"[objdump] → {os.path.basename(dump)}", "#98c379")

    return True, (
        f"Build complete → output/{canvas_name}/\n"
        f"  {canvas_name}.elf\n"
        f"  {canvas_name}.bin\n"
        f"  {canvas_name}.mem\n"
        f"  {canvas_name}_be.hex\n"
        f"  {canvas_name}.dump"
    )


# ---------------------------------------------------------------------------
# CLI entry-point (quick smoke-test)
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    name = sys.argv[1] if len(sys.argv) > 1 else "test_canvas"
    ok, msg = build(name)
    print(msg)
    sys.exit(0 if ok else 1)
