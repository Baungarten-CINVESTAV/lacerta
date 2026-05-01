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
/*
 *-------------------------------------------------------------
 *
 * user_project_wrapper
 *
 * This wrapper enumerates all of the pins available to the
 * user for the user project.
 *
 * An example user project is provided in this wrapper.  The
 * example should be removed and replaced with the actual
 * user project.
 *
 *-------------------------------------------------------------
 */

module user_project_wrapper #(
    parameter BITS = 32
) (
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // Analog (direct connection to GPIO pad---use with caution)
    // Note that analog I/O is not available on the 7 lowest-numbered
    // GPIO pads, and so the analog_io indexing is offset from the
    // GPIO indexing by 7 (also upper 2 GPIOs do not have analog_io).
    inout [`MPRJ_IO_PADS-10:0] analog_io,

    // Independent clock (on independent integer divider)
    input   user_clock2,

    // User maskable interrupt signals
    output [2:0] user_irq
);

/*--------------------------------------*/
/* User project is instantiated  here   */
/*--------------------------------------*/
/*--------------------------------------*/
/* User project is instantiated  here   */
/*--------------------------------------*/
/*
Mode	OEB Signal	GPIO Pin State	Description
Input	1 (HIGH)	Hi-Z	Configured as an input, receiving external signals.
Output	0 (LOW)	Driven by design	Configured as an output, actively sending signals.
Bidirectional	Varies	Hi-Z or Driven	Dynamically switches between input and output based on OEB.
*/
/*
assign io_oeb[0]  = 1'b0;
assign io_oeb[1]  = 1'b0;
assign io_oeb[2]  = 1'b0;
assign io_oeb[3]  = 1'b0;
assign io_oeb[4]  = 1'b0;
*/
assign io_oeb[5]  = 1'b1; // UART TX - input
assign io_oeb[6]  = 1'b0; // UART RX - output
assign io_oeb[7]  = 1'b0; // Mem addr 15- output
assign io_oeb[8]  = 1'b0; // Mem addr 14- output
assign io_oeb[9]  = 1'b0; // Mem addr 13- output
assign io_oeb[10] = 1'b0; // Mem addr 12- output
assign io_oeb[11] = 1'b0; // Mem addr 11- output
assign io_oeb[12] = 1'b0; // Mem addr 10- output
assign io_oeb[13] = 1'b0; // Mem addr 9- output
assign io_oeb[14] = 1'b0; // Mem addr 8- output
assign io_oeb[15] = 1'b0; // Mem addr 7- output
assign io_oeb[16] = 1'b0; // Mem addr 6- output
assign io_oeb[17] = 1'b0; // Mem addr 5- output
assign io_oeb[18] = 1'b0; // Mem addr 4- output
assign io_oeb[19] = 1'b0; // Mem addr 3- output
assign io_oeb[20] = 1'b0; // Mem addr 2- output
assign io_oeb[21] = 1'b0; // Mem addr 1- output
assign io_oeb[22] = 1'b0; // Mem addr 0- output
assign io_oeb[23] = 1'b0; // MemIO-0 according to XXXXX signal -- 0 for output, 1 for input
assign io_oeb[24] = 1'b0; // MemIO-1 according to XXXXX signal -- 0 for output, 1 for input
assign io_oeb[25] = 1'b0; // MemIO-2 according to XXXXX signal -- 0 for output, 1 for input
assign io_oeb[26] = 1'b0; // MemIO-3 according to XXXXX signal -- 0 for output, 1 for input
assign io_oeb[27] = 1'b0; // MemIO-4 according to XXXXX signal -- 0 for output, 1 for input
assign io_oeb[28] = 1'b0; // MemIO-5 according to XXXXX signal -- 0 for output, 1 for input
assign io_oeb[29] = 1'b0; // MemIO-6 according to XXXXX signal -- 0 for output, 1 for input
assign io_oeb[30] = 1'b0; // MemIO-7 according to XXXXX signal -- 0 for output, 1 for input
assign io_oeb[31] = 1'b0; // Mem WE
assign io_oeb[32] = 1'b0; // Mem OE
assign io_oeb[33] = 1'b0; // sck    
assign io_oeb[34] = 1'b0; // cs
assign io_oeb[35] = 1'b0; // mosi
assign io_oeb[36] = 1'b0; // dc
assign io_oeb[37] = 1'b1; // reset



assign la_data_out = 128'b0;
assign user_irq = 3'b0;

dig_top dig_top (
  .clk                (wb_clk_i),
  .arst_n             (io_in[37]),

  // uprocessor interface
  .up_soft_reset      (),

  // UART interface
  .rx                 (io_in[5]),
  .tx                 (io_out[6]),
    

  // Wishbone interface
  .wb_adr_i           (wbs_adr_i), // Address input
  .wb_dat_i           (wbs_dat_i), // Data input
  .wb_dat_o           (wbs_dat_o), // Data output
  .wb_we_i            (wbs_we_i),  // Write enable
  .wb_sel_i           (wbs_sel_i), // Byte select
  .wb_stb_i           (wbs_stb_i), // Strobe
  .wb_cyc_i           (wbs_cyc_i), // Cycle valid
  .wb_ack_o           (wbs_ack_o), // Acknowledge

  // SRAM interface
  .sram_addr          ({io_out[7], io_out[8], io_out[9], io_out[10], io_out[11], io_out[12], io_out[13], io_out[14],io_out[15],io_out[16],io_out[17],io_out[18],io_out[19],io_out[20],io_out[21],io_out[22]}),
  .sram_data          (io_out[30:23]), //TODO: SPLIT ON INTPUT AND OUTPUT PORT
  .sram_ce_n          (), //Intentionally not connected
  .sram_oe_n          (io_out[32]),
  .sram_we_n          (io_out[31]),
  .sram_lb_n          (), //Intentionally not connected

  // TFT ports
  .sck                (io_out[33]),
  .ss                 (io_out[34]),
  .mosi               (io_out[35]),
  // data/command send to tft screen
  .dc                 (io_out[36]),
  .res                (io_out[37]),
  .blk                () //Intentionally not connected

);



endmodule	// user_project_wrapper

`default_nettype wire
