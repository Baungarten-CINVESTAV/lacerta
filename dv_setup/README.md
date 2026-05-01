# DV Setup

This folder contains one helper script:

- `dv_io_ports_setup.sh`

Despite the name, it is not limited to `io_ports`. It can run any DV test
folder under `verilog/dv/` as long as that folder has a working `Makefile`.

## Quick Start

From the repository root:

```bash
./dv_setup/dv_io_ports_setup.sh verify-host
```

That command:

- uses `SIM_MODE=RTL` by default
- uses `DV_TEST=io_ports` by default
- installs the custom `mgmt_core_wrapper/verilog/dv/make/sim.makefile`
- refreshes the GL include patch files before simulation
- runs `make verify-io_ports`

## Initial Setup

Use this section the first time you prepare the DV environment.

### Option 1: Run on the Host

If you want to run simulations directly on your machine:

1. Install the required host packages:

```bash
./dv_setup/dv_io_ports_setup.sh install-host
```

2. Build the local RISC-V toolchain:

```bash
./dv_setup/dv_io_ports_setup.sh build-toolchain
```

3. Check the variables the script will use:

```bash
./dv_setup/dv_io_ports_setup.sh env
```

4. Run a first RTL test:

```bash
./dv_setup/dv_io_ports_setup.sh verify-host
```

### Option 2: Run in Docker

If you want to run simulations inside the DV container:

1. Install the host packages needed to support the flow:

```bash
./dv_setup/dv_io_ports_setup.sh install-host
```

2. Pull the DV Docker image:

```bash
./dv_setup/dv_io_ports_setup.sh pull-docker
```

3. Check the variables the script will use:

```bash
./dv_setup/dv_io_ports_setup.sh env
```

4. Run a first RTL test in Docker:

```bash
./dv_setup/dv_io_ports_setup.sh verify-docker
```

### One-Command Setup

If you want the script to do the preparation and the first run in one step:

```bash
./dv_setup/dv_io_ports_setup.sh all-host
```

or:

```bash
./dv_setup/dv_io_ports_setup.sh all-docker
```

### What the Script Assumes

Before running simulations, the script expects this repository layout:

```bash
caravel/
mgmt_core_wrapper/
verilog/dv/
dependencies/pdks/sky130A
```

It also assumes:

- the SKY130 PDK is available under `dependencies/pdks`
- the local host toolchain will be installed under `/opt/riscv32i`
- Docker is installed if you plan to use `verify-docker`

## Automatic Patches Applied by the Script

The helper script now keeps two DV-related patches in place:

- it installs the project-specific [sim.makefile](/home/baungarten/Desktop/lacerta_march/mgmt_core_wrapper/verilog/dv/make/sim.makefile) into `mgmt_core_wrapper/verilog/dv/make/sim.makefile`
- it refreshes the GL include lists under `verilog/includes/`

This happens automatically when you run:

```bash
./dv_setup/dv_io_ports_setup.sh verify-host
./dv_setup/dv_io_ports_setup.sh verify-docker
./dv_setup/dv_io_ports_setup.sh all-host
./dv_setup/dv_io_ports_setup.sh all-docker
```

If you only want to apply the patches without starting a simulation, you can run:

```bash
./dv_setup/dv_io_ports_setup.sh patch-sim
./dv_setup/dv_io_ports_setup.sh patch-gl
```

## Pick the Test You Want

Choose the DV folder with `DV_TEST`.

Examples:

```bash
DV_TEST=io_ports ./dv_setup/dv_io_ports_setup.sh verify-host
DV_TEST=la_test1 ./dv_setup/dv_io_ports_setup.sh verify-host
DV_TEST=la_test2 ./dv_setup/dv_io_ports_setup.sh verify-host
DV_TEST=wb_port ./dv_setup/dv_io_ports_setup.sh verify-host
DV_TEST=mprj_stimulus ./dv_setup/dv_io_ports_setup.sh verify-host
```

The script does not use a hardcoded list anymore. It just checks that this
folder exists:

```bash
verilog/dv/$DV_TEST
```

So if you create a new DV folder such as:

```bash
verilog/dv/my_new_test
```

and it has a valid `Makefile`, you can run it with:

```bash
DV_TEST=my_new_test ./dv_setup/dv_io_ports_setup.sh verify-host
```

## Pick the Simulation Type

Choose the simulation mode with `SIM_MODE`.

Examples:

```bash
SIM_MODE=RTL DV_TEST=io_ports ./dv_setup/dv_io_ports_setup.sh verify-host
SIM_MODE=GL DV_TEST=io_ports ./dv_setup/dv_io_ports_setup.sh verify-host
SIM_MODE=GL_SDF DV_TEST=io_ports ./dv_setup/dv_io_ports_setup.sh verify-host
```

## Host or Docker

Use `verify-host` if you want to run with tools installed on your machine.

```bash
DV_TEST=la_test1 SIM_MODE=RTL ./dv_setup/dv_io_ports_setup.sh verify-host
```

Use `verify-docker` if you want to run inside the DV Docker image.

```bash
DV_TEST=la_test1 SIM_MODE=RTL ./dv_setup/dv_io_ports_setup.sh verify-docker
```

## Main Commands

```bash
./dv_setup/dv_io_ports_setup.sh verify-host
./dv_setup/dv_io_ports_setup.sh verify-docker
./dv_setup/dv_io_ports_setup.sh patch-sim
./dv_setup/dv_io_ports_setup.sh patch-gl
./dv_setup/dv_io_ports_setup.sh env
./dv_setup/dv_io_ports_setup.sh install-host
./dv_setup/dv_io_ports_setup.sh build-toolchain
./dv_setup/dv_io_ports_setup.sh pull-docker
./dv_setup/dv_io_ports_setup.sh all-host
./dv_setup/dv_io_ports_setup.sh all-docker
```

What they do:

- `verify-host`: run the chosen DV test on the host
- `verify-docker`: run the chosen DV test in Docker
- `patch-sim`: install the custom DV [sim.makefile](/home/baungarten/Desktop/lacerta_march/mgmt_core_wrapper/verilog/dv/make/sim.makefile) into `mgmt_core_wrapper/verilog/dv/make/`
- `patch-gl`: refresh the GL include files while preserving the `# Caravel user project includes` section
- `env`: print the variables the script is using
- `install-host`: install host packages
- `build-toolchain`: build the local RISC-V toolchain
- `pull-docker`: pull the DV Docker image
- `all-host`: install, build, patch the DV files, then run on the host
- `all-docker`: install, pull, patch the DV files, then run in Docker

## Default Variables

If you do not override them, the script uses:

```bash
TARGET_PATH=<repo-root>
CARAVEL_ROOT=<repo-root>/caravel
MCW_ROOT=<repo-root>/mgmt_core_wrapper
PDK_ROOT=<repo-root>/dependencies/pdks
PDK=sky130A
TOOLCHAIN_ROOT=/opt/riscv32i
SIM_MODE=RTL
DV_TEST=io_ports
```

You can override any of them from the shell. Example:

```bash
SIM_MODE=GL DV_TEST=my_new_test ./dv_setup/dv_io_ports_setup.sh verify-host
```

## Notes

- `verify-host` expects a local toolchain at `/opt/riscv32i` by default and
  uses `riscv32-unknown-elf`.
- `verify-docker` uses `efabless/dv_setup:latest`.
- `patch-sim` is useful after reinstalling or replacing `mgmt_core_wrapper`,
  because it restores the custom DV simulation rules expected by this project.
- `patch-gl` updates the GL include lists so the Caravel paths match the
  actual files in this repository, and it preserves the existing user-project
  include section instead of overwriting it.
- `SIM_MODE=GL_SDF` now uses `iverilog` and `vvp` with `-gspecify`,
  `-DENABLE_SDF`, and `vvp -sdf-verbose`.
- Commands that install packages, build the toolchain, or pull Docker images
  require `sudo` and/or network access.
