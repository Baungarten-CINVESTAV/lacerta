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

`default_nettype none

`ifndef __GLOBAL_DEFINE_H
// Global parameters
`define __GLOBAL_DEFINE_H

`define MPRJ_IO_PADS_1 19	/* number of user GPIO pads on user1 side */
`define MPRJ_IO_PADS_2 19	/* number of user GPIO pads on user2 side */
`define MPRJ_IO_PADS (`MPRJ_IO_PADS_1 + `MPRJ_IO_PADS_2)

`define MPRJ_PWR_PADS_1 2	/* vdda1, vccd1 enable/disable control */
`define MPRJ_PWR_PADS_2 2	/* vdda2, vccd2 enable/disable control */
`define MPRJ_PWR_PADS (`MPRJ_PWR_PADS_1 + `MPRJ_PWR_PADS_2)

// Analog pads are only used by the "caravan" module and associated
// modules such as user_analog_project_wrapper and chip_io_alt.

`define ANALOG_PADS_1 5
`define ANALOG_PADS_2 6

`define ANALOG_PADS (`ANALOG_PADS_1 + `ANALOG_PADS_2)

// Size of soc_mem_synth

// Type and size of soc_mem
// `define USE_OPENRAM
`define USE_CUSTOM_DFFRAM
// don't change the following without double checking addr widths
`define MEM_WORDS 256

// Number of columns in the custom memory; takes one of three values:
// 1 column : 1 KB, 2 column: 2 KB, 4 column: 4KB
`define DFFRAM_WSIZE 4
`define DFFRAM_USE_LATCH 0

// not really parameterized but just to easily keep track of the number
// of ram_block across different modules
`define RAM_BLOCKS 1

// Clock divisor default value
`define CLK_DIV 3'b010

// GPIO control default mode and enable for most I/Os
// Most I/Os set to be user input pins on startup.
// NOTE:  To be modified, with GPIOs 5 to 35 being set from a build-time-
// programmable block.
`define MGMT_INIT 1'b0
`define OENB_INIT 1'b0
`define DM_INIT 3'b001

`endif // __GLOBAL_DEFINE_H






//`define FPGA 1
// Timing parameters
parameter CLOCK_FREQUENCY = 50_000_000; // 50 MHz
// Memory parameters
`ifdef FPGA
	parameter MAIN_MEM_ADDR_WIDTH = 19;
`else
	parameter MAIN_MEM_ADDR_WIDTH = 10;
`endif
parameter MAIN_MEM_DATA_WIDTH = 8;
parameter MAIN_MEM_DATA_BYTES = (MAIN_MEM_DATA_WIDTH/8) > 1 ? (MAIN_MEM_DATA_WIDTH/8) : 1;

// Communication protocol parameters (uart/wishbone)
parameter UART_BYTES_DATA = 4;
parameter UART_BYTES_ADDRESS = 1;
parameter WB_ADDR_WIDTH = 32;
parameter WB_DATA_WIDTH = 32;

// VGA timing parameters for 640x480 60Hz
//	Horizontal Parameter		( Pixel )
parameter	H_SYNC_CYC	=	96;
parameter	H_SYNC_BACK	=	48;
parameter	H_SYNC_FRONT=	16;
parameter	H_SYNC_DEACT =	H_SYNC_CYC + H_SYNC_BACK + H_SYNC_FRONT; // total deactivated timing
parameter	H_SYNC_ACT	=	640/* + 1*/;
parameter	H_SYNC_TOTAL=	H_SYNC_ACT + H_SYNC_DEACT;
//	Vertical Parameter		( Line )
parameter	V_SYNC_CYC	=	2;
parameter	V_SYNC_BACK	=	31;
parameter	V_SYNC_FRONT=	11;
parameter	V_SYNC_DEACT =	V_SYNC_CYC + V_SYNC_BACK + V_SYNC_FRONT; // total deactivated timing
parameter	V_SYNC_ACT	=	480/* + 1*/;
parameter	V_SYNC_TOTAL=	V_SYNC_ACT + V_SYNC_DEACT;

// Video streaming configuration
parameter VGA_RED_WIDTH = MAIN_MEM_DATA_WIDTH-1;
parameter VGA_GREEN_WIDTH = MAIN_MEM_DATA_WIDTH-1;
parameter VGA_BLUE_WIDTH = MAIN_MEM_DATA_WIDTH-1;
parameter FRAME_WIDTH = 640;
parameter FRAME_HEIGHT = 480;
parameter FRAME_SIZE = FRAME_WIDTH*FRAME_HEIGHT;

// Memory system parameters
parameter NUM_READ_BUFFERS = 4;
parameter NUM_ELEMENTS_READ_BUFFERS = 128;
parameter NUM_WRITE_BUFFERS = 3;
parameter NUM_ELEMENTS_WRITE_BUFFERS = 16;
parameter UP_RESET_VECTOR = 32'h2000_0000;
parameter MMIO_MEM_OFFSET = 32'h8000_0000;
parameter UP_INSTR_OFFSET = 640*480+50_000;
