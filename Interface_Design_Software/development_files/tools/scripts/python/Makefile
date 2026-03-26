export PATH := /opt/riscv/bin:$(PATH)

CROSS   := riscv64-unknown-elf
GCC     := $(CROSS)-gcc
OBJCOPY := $(CROSS)-objcopy
OBJDUMP := $(CROSS)-objdump

ARCH    := rv32i
ABI     := ilp32
LD      := linker.ld

# -mbig-endian
GCCFLAGS := -march=$(ARCH) -mabi=$(ABI) -nostartfiles 

# Default test — override with: make TEST=c_program_2
TEST    ?= program

# Parse "make spike <testname>" — e.g. make spike c_program_7_test
ifneq ($(filter spike,$(MAKECMDGOALS)),)
  _SPIKE_TEST := $(filter-out spike,$(MAKECMDGOALS))
  ifneq ($(_SPIKE_TEST),)
    override TEST := $(word 1,$(_SPIKE_TEST))
  endif
endif

TESTDIR := tests/$(TEST)
ELF     := $(TESTDIR)/$(TEST).elf
HEX     := $(TESTDIR)/$(TEST).hex
BIN     := $(TESTDIR)/$(TEST).bin
MEM     := $(TESTDIR)/$(TEST).mem
MEM_BE  := $(TESTDIR)/$(TEST)_be.hex
DUMP    := $(TESTDIR)/$(TEST).dump

# Auto-detect source type: .S (assembly) or .c (C)
SRC_S   := $(wildcard $(TESTDIR)/$(TEST).S)
SRC_C   := $(wildcard $(TESTDIR)/$(TEST).c)

ifneq ($(SRC_S),)
  SRCS        := $(SRC_S)
  CFLAGS_EXTRA :=
else ifneq ($(SRC_C),)
  SRCS        := crt0.S $(wildcard $(TESTDIR)/*.S) $(SRC_C)
  CFLAGS_EXTRA := -O2
else
  $(error No source found in $(TESTDIR): expected $(TEST).S or $(TEST).c)
endif

# Auto-discover available tests from subdirectories
TESTS   := $(notdir $(wildcard tests/*))

SPIKE_MEM     := 0x20000000:0xFA0,0x80000000:0x1000
SPIKE_TIMEOUT ?= 5

.PHONY: all clean clean-all spike $(TESTS)

# Default: build the selected test (full pipeline)
all: $(MEM_BE) $(DUMP)

# Shorthand targets — e.g. make c_program_2
$(TESTS):
	$(MAKE) TEST=$@

# 1. Compile source → ELF
$(ELF): $(SRCS) $(LD)
	$(GCC) $(GCCFLAGS) $(CFLAGS_EXTRA) -T $(LD) -o $@ $(SRCS)

# 2. ELF → Verilog hex
$(HEX): $(ELF)
	$(OBJCOPY) -O verilog --verilog-data-width=1 $< $@

# 3. ELF → raw binary
$(BIN): $(ELF)
	$(OBJCOPY) -O binary $< $@

# 4. Binary → byte-per-line mem
$(MEM): $(BIN)
	hexdump -v -e '1/1 "%02X\n"' $< > $@

# 5. Little-endian .mem → big-endian .mem
$(MEM_BE): $(HEX) $(MEM)
	python3 be.py $(MEM) $@

# 6. ELF → disassembly dump
$(DUMP): $(ELF)
	$(OBJDUMP) -d $< > $@

# Simulate with Spike: make spike TEST=<name>  or  make spike <name>
#   Binary runs from 0x20000000; execution trace saved to .spike.log
#   Programs with infinite loops are killed after SPIKE_TIMEOUT seconds (default 5)
spike: $(ELF)
	@echo "[spike] Simulating $(ELF) (max $(SPIKE_TIMEOUT)s) ..."
	spike \
		--isa=$(ARCH) \
		--instructions=1000000 \
		--priv=m \
		-m$(SPIKE_MEM) \
		--pc=0x20000000 \
		--log-commits \
		-l \
		--log=$(TESTDIR)/$(TEST).spike.log \
		$(ELF)
	@echo "[spike] Execution log: $(TESTDIR)/$(TEST).spike.log"

	python3 spike_bucket.py $(TESTDIR)/$(TEST).spike.log $(TESTDIR)/$(TEST).spike.membucket.log

# Clean all test artifacts
clean:
	$(foreach t,$(TESTS),rm -f tests/$(t)/$(t).elf tests/$(t)/$(t).hex tests/$(t)/$(t).bin tests/$(t)/$(t).mem tests/$(t)/$(t)_be.hex tests/$(t)/$(t).dump tests/$(t)/$(t).spike.log;)
