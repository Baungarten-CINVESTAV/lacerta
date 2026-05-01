#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

TARGET_PATH="${TARGET_PATH:-$REPO_ROOT}"
CARAVEL_ROOT="${CARAVEL_ROOT:-$REPO_ROOT/caravel}"
MCW_ROOT="${MCW_ROOT:-$REPO_ROOT/mgmt_core_wrapper}"
PDK_ROOT="${PDK_ROOT:-$REPO_ROOT/dependencies/pdks}"
PDK="${PDK:-sky130A}"

TOOLCHAIN_ROOT="${TOOLCHAIN_ROOT:-/opt/riscv32i}"
TOOLCHAIN_REPO="${TOOLCHAIN_REPO:-$REPO_ROOT/riscv-gnu-toolchain-rv32i}"
TOOLCHAIN_COMMIT="${TOOLCHAIN_COMMIT:-411d134}"
GCC_PREFIX_HOST="${GCC_PREFIX_HOST:-riscv32-unknown-elf}"
SIM_MODE="${SIM_MODE:-RTL}"
DV_TEST="${DV_TEST:-io_ports}"

DOCKER_IMAGE="${DOCKER_IMAGE:-efabless/dv_setup:latest}"
DOCKER_TOOLS="${DOCKER_TOOLS:-/foss/tools/riscv-gnu-toolchain-rv32i/411d134}"
GCC_PREFIX_DOCKER="${GCC_PREFIX_DOCKER:-riscv32-unknown-linux-gnu}"

APT_PACKAGES=(
  iverilog
  autoconf
  automake
  autotools-dev
  curl
  libmpc-dev
  libmpfr-dev
  libgmp-dev
  gawk
  build-essential
  bison
  flex
  texinfo
  gperf
  libtool
  patchutils
  bc
  zlib1g-dev
  git
  libexpat1-dev
)

usage() {
  cat <<EOF
Usage: $(basename "$0") <command>

Commands:
  install-host      Install apt packages needed for DV and the RISC-V toolchain.
  build-toolchain   Clone and build the rv32i toolchain into ${TOOLCHAIN_ROOT}.
  pull-docker       Pull ${DOCKER_IMAGE}.
  patch-sim         Install the custom mgmt_core_wrapper DV sim.makefile.
  patch-gl          Apply the GL include-file fixes for Caravel paths and gpio defaults.
  verify-host       Run SIM=${SIM_MODE} make verify-${DV_TEST} on the host.
  verify-docker     Run SIM=${SIM_MODE} make verify-${DV_TEST} inside the DV Docker image.
  all-host          Install packages, build the toolchain, patch DV makefiles and GL includes, then verify on the host.
  all-docker        Install packages, pull the Docker image, patch DV makefiles and GL includes, then verify in Docker.
  env               Print the environment variables used by this script.

Examples:
  ./dv_setup/dv_io_ports_setup.sh verify-host
  DV_TEST=la_test1 ./dv_setup/dv_io_ports_setup.sh verify-host
  SIM_MODE=GL ./dv_setup/dv_io_ports_setup.sh verify-host
  ./dv_setup/dv_io_ports_setup.sh verify-docker
  ./dv_setup/dv_io_ports_setup.sh all-docker
EOF
}

require_dir() {
  local path="$1"
  local label="$2"
  if [[ ! -d "$path" ]]; then
    echo "Missing ${label}: $path" >&2
    exit 1
  fi
}

check_repo_layout() {
  require_dir "$TARGET_PATH" "TARGET_PATH"
  require_dir "$CARAVEL_ROOT" "CARAVEL_ROOT"
  require_dir "$MCW_ROOT" "MCW_ROOT"
  require_dir "$PDK_ROOT/$PDK" "PDK_ROOT/$PDK"
  require_dir "$TARGET_PATH/verilog/dv" "DV directory"
  require_dir "$TARGET_PATH/verilog/dv/$DV_TEST" "DV test directory"
}

print_env() {
  cat <<EOF
TARGET_PATH=$TARGET_PATH
CARAVEL_ROOT=$CARAVEL_ROOT
MCW_ROOT=$MCW_ROOT
PDK_ROOT=$PDK_ROOT
PDK=$PDK
TOOLCHAIN_ROOT=$TOOLCHAIN_ROOT
TOOLCHAIN_REPO=$TOOLCHAIN_REPO
TOOLCHAIN_COMMIT=$TOOLCHAIN_COMMIT
GCC_PREFIX_HOST=$GCC_PREFIX_HOST
SIM_MODE=$SIM_MODE
DV_TEST=$DV_TEST
DOCKER_IMAGE=$DOCKER_IMAGE
DOCKER_TOOLS=$DOCKER_TOOLS
GCC_PREFIX_DOCKER=$GCC_PREFIX_DOCKER
EOF
}

install_sim_makefile() {
  check_repo_layout
  mkdir -p "$MCW_ROOT/verilog/dv/make"

  cat > "$MCW_ROOT/verilog/dv/make/sim.makefile" <<'EOF'
# SPDX-FileCopyrightText: 2020 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0


export IVERILOG_DUMPER = fst

# RTL/GL/GL_SDF
SIM?=RTL


.SUFFIXES:


all:  ${BLOCKS:=.vcd} ${BLOCKS:=.lst}

hex:  ${BLOCKS:=.hex}

#.SUFFIXES:

##############################################################################
# Comiple firmeware
##############################################################################
%.elf: %.c $(LINKER_SCRIPT) $(SOURCE_FILES)
	${GCC_PATH}/${GCC_PREFIX}-gcc -g \
	-I$(FIRMWARE_PATH) \
	-I$(VERILOG_PATH)/dv/generated \
	-I$(VERILOG_PATH)/dv/ \
	-I$(VERILOG_PATH)/common \
	  $(CPUFLAGS) \
	-Wl,-Bstatic,-T,$(LINKER_SCRIPT),--strip-debug \
	-ffreestanding -nostdlib -o $@ $(SOURCE_FILES) $<

%.lst: %.elf
	${GCC_PATH}/${GCC_PREFIX}-objdump -d -S $< > $@

%.hex: %.elf
	${GCC_PATH}/${GCC_PREFIX}-objcopy -O verilog $< $@
	# to fix flash base address
	sed -ie 's/@10/@00/g' $@

%.bin: %.elf
	${GCC_PATH}/${GCC_PREFIX}-objcopy -O binary $< /dev/stdout | tail -c +1048577 > $@


##############################################################################
# Runing the simulations
##############################################################################

%.vvp: %_tb.v %.hex

## RTL
ifeq ($(SIM),RTL)
    ifeq ($(CONFIG),caravel_user_project)
		iverilog -g2012 -I$(USER_PROJECT_VERILOG)/rtl -Ttyp -DFUNCTIONAL -DSIM -DUSE_POWER_PINS -DUNIT_DELAY=#1 \
    -f$(VERILOG_PATH)/includes/includes.rtl.caravel \
    -f$(USER_PROJECT_VERILOG)/includes/includes.rtl.$(CONFIG) -o $@ $<

    else
		iverilog -g2012 -Ttyp -DFUNCTIONAL -DSIM -DUSE_POWER_PINS -DUNIT_DELAY=#1 \
		-f $(VERILOG_PATH)/includes/includes.rtl.$(CONFIG) \
		-o $@ $(CARAVEL_PATH)/rtl/__user_project_wrapper.v $<
    endif
endif

## GL
ifeq ($(SIM),GL)
    ifeq ($(CONFIG),caravel_user_project)
		iverilog -g2012 -I$(USER_PROJECT_VERILOG)/rtl -Ttyp -DFUNCTIONAL -DGL -DSIM -DUSE_POWER_PINS -DUNIT_DELAY=#1 \
        -f$(VERILOG_PATH)/includes/includes.gl.caravel \
        -f$(USER_PROJECT_VERILOG)/includes/includes.gl.$(CONFIG) -o $@ $<
    else
		iverilog -g2012 -Ttyp -DFUNCTIONAL -DGL -DSIM -DUSE_POWER_PINS -DUNIT_DELAY=#1 \
        -f$(VERILOG_PATH)/includes/includes.gl.$(CONFIG) \
		-o $@ $(CARAVEL_PATH)/gl/__user_project_wrapper.v $<
    endif
endif

## GL+SDF
ifeq ($(SIM),GL_SDF)
    ifeq ($(CONFIG),caravel_user_project)
		cvc64  +interp \
		+define+SIM +define+FUNCTIONAL +define+GL +define+USE_POWER_PINS +define+UNIT_DELAY +define+ENABLE_SDF \
		+change_port_type +dump2fst +fst+parallel2=on   +nointeractive +notimingchecks +mipdopt \
		-f $(VERILOG_PATH)/includes/includes.gl+sdf.caravel \
		-f $(USER_PROJECT_VERILOG)/includes/includes.gl+sdf.$(CONFIG) $<
	else
		cvc64  +interp \
		+define+SIM +define+FUNCTIONAL +define+GL +define+USE_POWER_PINS +define+UNIT_DELAY +define+ENABLE_SDF \
		+change_port_type +dump2fst +fst+parallel2=on   +nointeractive +notimingchecks +mipdopt \
		-f $(VERILOG_PATH)/includes/includes.gl+sdf.$(CONFIG) \
		-f $CARAVEL_PATH/gl/__user_project_wrapper.v $<
    endif
endif

%.vcd: %.vvp

ifeq ($(SIM),RTL)
	vvp  $<
	 mv $@ RTL-$@
endif
ifeq ($(SIM),GL)
	vvp  $<
	 mv $@ GL-$@
endif
ifeq ($(SIM),GL_SDF)
	 mv $@ GL_SDF-$@
endif

# twinwave: RTL-%.vcd GL-%.vcd
#     twinwave RTL-$@ * + GL-$@ *

check-env:
ifndef PDK_ROOT
	$(error PDK_ROOT is undefined, please export it before running make)
endif
ifeq (,$(wildcard $(PDK_ROOT)/$(PDK)))
	$(error $(PDK_ROOT)/$(PDK) not found, please install pdk before running make)
endif
ifeq (,$(wildcard $(GCC_PATH)/$(GCC_PREFIX)-gcc ))
	$(error $(GCC_PATH)/$(GCC_PREFIX)-gcc is not found, please export GCC_PATH and GCC_PREFIX before running make)
endif
# check for efabless style installation
ifeq (,$(wildcard $(PDK_ROOT)/$(PDK)/libs.ref/*/verilog))
SIM_DEFINES := ${SIM_DEFINES} -DEF_STYLE
endif


# ---- Clean ----

clean:
	\rm  -f *.elf *.hex *.bin *.vvp *.log *.vcd *.lst *.hexe

.PHONY: clean hex all
EOF
}

patch_gl_includes() {
  check_repo_layout

  write_gl_include_file() {
    cat <<EOF
# SPDX-FileCopyrightText: 2020 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# SPDX-License-Identifier: Apache-2.0

# Caravel user project includes
-v \$(USER_PROJECT_VERILOG)/gl/user_project_wrapper.v
-v \$(USER_PROJECT_VERILOG)/gl/user_proj_example.v

# Automatically generated with user I/O config from user_defines.v
# by caravel/scripts/gen_gpio_defaults.py
-v \$(CARAVEL_PATH)/gl/caravel_core.v
-v \$(CARAVEL_PATH)/gl/gpio_defaults_block_0403.v
-v \$(CARAVEL_PATH)/gl/gpio_defaults_block_0801.v
-v \$(CARAVEL_PATH)/gl/gpio_defaults_block_1803.v
EOF
  }

  write_gl_gpio_tail() {
    cat <<EOF
# Automatically generated with user I/O config from user_defines.v
# by caravel/scripts/gen_gpio_defaults.py
-v \$(CARAVEL_PATH)/gl/caravel_core.v
-v \$(CARAVEL_PATH)/gl/gpio_defaults_block_0403.v
-v \$(CARAVEL_PATH)/gl/gpio_defaults_block_0801.v
-v \$(CARAVEL_PATH)/gl/gpio_defaults_block_1803.v
EOF
  }

  write_gl_sdf_include_file() {
    cat <<EOF
// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

\$USER_PROJECT_VERILOG/gl/user_project_wrapper.v
\$USER_PROJECT_VERILOG/gl/user_proj_example.v

// Automatically generated with user I/O config from user_defines.v
// by caravel/scripts/gen_gpio_defaults.py
\$CARAVEL_PATH/gl/caravel_core.v
\$CARAVEL_PATH/gl/gpio_defaults_block_0403.v
\$CARAVEL_PATH/gl/gpio_defaults_block_0801.v
\$CARAVEL_PATH/gl/gpio_defaults_block_1803.v
EOF
  }

  write_gl_sdf_gpio_tail() {
    cat <<EOF
// Automatically generated with user I/O config from user_defines.v
// by caravel/scripts/gen_gpio_defaults.py
\$CARAVEL_PATH/gl/caravel_core.v
\$CARAVEL_PATH/gl/gpio_defaults_block_0403.v
\$CARAVEL_PATH/gl/gpio_defaults_block_0801.v
\$CARAVEL_PATH/gl/gpio_defaults_block_1803.v
EOF
  }

  preserve_include_prefix() {
    local file_path="$1"
    local marker="$2"
    local full_writer="$3"
    local tail_writer="$4"
    local tmp_file

    if [[ -f "$file_path" ]] && grep -Fq "$marker" "$file_path"; then
      tmp_file="$(mktemp)"
      awk -v marker="$marker" '
        index($0, marker) { exit }
        { print }
      ' "$file_path" > "$tmp_file"

      {
        cat "$tmp_file"
        printf '\n'
        "$tail_writer"
      } > "$file_path"

      rm -f "$tmp_file"
    else
      "$full_writer" > "$file_path"
    fi
  }

  preserve_include_prefix \
    "$TARGET_PATH/verilog/includes/includes.gl.caravel_user_project" \
    "# Automatically generated with user I/O config from user_defines.v" \
    write_gl_include_file \
    write_gl_gpio_tail

  preserve_include_prefix \
    "$TARGET_PATH/verilog/includes/includes.gl+sdf.caravel_user_project" \
    "// Automatically generated with user I/O config from user_defines.v" \
    write_gl_sdf_include_file \
    write_gl_sdf_gpio_tail
}

install_host_packages() {
  sudo apt-get update
  sudo apt-get install -y "${APT_PACKAGES[@]}"
}

build_toolchain() {
  check_repo_layout

  if [[ ! -d "$TOOLCHAIN_REPO/.git" ]]; then
    git clone https://github.com/riscv/riscv-gnu-toolchain "$TOOLCHAIN_REPO"
  fi

  git -C "$TOOLCHAIN_REPO" fetch --tags --all
  git -C "$TOOLCHAIN_REPO" checkout "$TOOLCHAIN_COMMIT"
  git -C "$TOOLCHAIN_REPO" submodule update --init --recursive

  sudo mkdir -p "$TOOLCHAIN_ROOT"
  sudo chown "$USER" "$TOOLCHAIN_ROOT"

  mkdir -p "$TOOLCHAIN_REPO/build"
  if [[ ! -x "$TOOLCHAIN_ROOT/bin/${GCC_PREFIX_HOST}-gcc" ]]; then
    (
      cd "$TOOLCHAIN_REPO/build"
      ../configure --with-arch=rv32i --prefix="$TOOLCHAIN_ROOT"
      make -j"$(nproc)"
    )
  fi
}

pull_docker() {
  docker pull "$DOCKER_IMAGE"
}

verify_host() {
  check_repo_layout
  install_sim_makefile
  patch_gl_includes

  export TARGET_PATH
  export CARAVEL_ROOT
  export MCW_ROOT
  export PDK_ROOT
  export PDK
  export TOOLS="$TOOLCHAIN_ROOT"
  export GCC_PREFIX="$GCC_PREFIX_HOST"
  export DESIGNS="$TARGET_PATH"
  export CORE_VERILOG_PATH="$TARGET_PATH/mgmt_core_wrapper/verilog"

  (
    cd "$TARGET_PATH/verilog/dv"
    SIM="$SIM_MODE" make "verify-${DV_TEST}"
  )
}

verify_docker() {
  check_repo_layout
  install_sim_makefile
  patch_gl_includes

  docker run --rm -it \
    -v "${TARGET_PATH}:${TARGET_PATH}" \
    -v "${PDK_ROOT}:${PDK_ROOT}" \
    -v "${CARAVEL_ROOT}:${CARAVEL_ROOT}" \
    -e TARGET_PATH="${TARGET_PATH}" \
    -e PDK_ROOT="${PDK_ROOT}" \
    -e PDK="${PDK}" \
    -e CARAVEL_ROOT="${CARAVEL_ROOT}" \
    -e TOOLS="${DOCKER_TOOLS}" \
    -e GCC_PREFIX="${GCC_PREFIX_DOCKER}" \
    -e DESIGNS="${TARGET_PATH}" \
    -e CORE_VERILOG_PATH="${TARGET_PATH}/mgmt_core_wrapper/verilog" \
    -e MCW_ROOT="${MCW_ROOT}" \
    -w "${TARGET_PATH}/verilog/dv" \
    "$DOCKER_IMAGE" \
    bash -lc "SIM=${SIM_MODE} make verify-${DV_TEST}"
}

main() {
  local command="${1:-}"

  case "$command" in
    install-host)
      install_host_packages
      ;;
    build-toolchain)
      build_toolchain
      ;;
    pull-docker)
      pull_docker
      ;;
    patch-sim)
      install_sim_makefile
      ;;
    patch-gl)
      patch_gl_includes
      ;;
    verify-host)
      verify_host
      ;;
    verify-docker)
      verify_docker
      ;;
    all-host)
      install_host_packages
      build_toolchain
      install_sim_makefile
      patch_gl_includes
      verify_host
      ;;
    all-docker)
      install_host_packages
      pull_docker
      install_sim_makefile
      patch_gl_includes
      verify_docker
      ;;
    env)
      print_env
      ;;
    -h|--help|help|"")
      usage
      ;;
    *)
      echo "Unknown command: $command" >&2
      usage
      exit 1
      ;;
  esac
}

main "$@"
