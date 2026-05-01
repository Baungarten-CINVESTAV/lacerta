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

`timescale 1 ns / 1 ps

`include "defines_lacerta.v" //INCLUDE THIS FILE FOR SIMULATION
module lacerta_tb;
	reg clock;
	reg RSTB;
	reg CSB;
	reg power1, power2;
	reg power3, power4;
	
	wire gpio;
	wire [37:0] mprj_io;

	assign mprj_io[3] = (CSB == 1'b1) ? 1'b1 : 1'bz;
	// assign mprj_io[3] = 1'b1;

	// External clock is used by default.  Make this artificially fast for the
	// simulation.  Normally this would be a slow clock and the digital PLL
	// would be the fast clock.

	always #10 clock <= (clock === 1'b0);

	initial begin
		clock = 0;
	end
	
	initial
	begin
	#100_000_000;
	$stop();
	end


	`ifdef ENABLE_SDF
		initial begin
			$sdf_annotate("../../../sdf/user_proj_example.sdf", uut.mprj) ;
			$sdf_annotate("../../../sdf/user_project_wrapper.sdf", uut.mprj.mprj) ;
			$sdf_annotate("../../../mgmt_core_wrapper/sdf/DFFRAM.sdf", uut.soc.DFFRAM_0) ;
			$sdf_annotate("../../../mgmt_core_wrapper/sdf/mgmt_core.sdf", uut.soc.core) ;
			$sdf_annotate("../../../caravel/sdf/housekeeping.sdf", uut.housekeeping) ;
			$sdf_annotate("../../../caravel/sdf/chip_io.sdf", uut.padframe) ;
			$sdf_annotate("../../../caravel/sdf/mprj_logic_high.sdf", uut.mgmt_buffers.mprj_logic_high_inst) ;
			$sdf_annotate("../../../caravel/sdf/mprj2_logic_high.sdf", uut.mgmt_buffers.mprj2_logic_high_inst) ;
			$sdf_annotate("../../../caravel/sdf/mgmt_protect_hv.sdf", uut.mgmt_buffers.powergood_check) ;
			$sdf_annotate("../../../caravel/sdf/mgmt_protect.sdf", uut.mgmt_buffers) ;
			$sdf_annotate("../../../caravel/sdf/caravel_clocking.sdf", uut.clocking) ;
			$sdf_annotate("../../../caravel/sdf/digital_pll.sdf", uut.pll) ;
			$sdf_annotate("../../../caravel/sdf/xres_buf.sdf", uut.rstb_level) ;
			$sdf_annotate("../../../caravel/sdf/user_id_programming.sdf", uut.user_id_value) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_bidir_1[0] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_bidir_1[1] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_bidir_2[0] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_bidir_2[1] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_bidir_2[2] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1[0] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1[1] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1[2] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1[3] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1[4] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1[5] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1[6] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1[7] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1[8] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1[9] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1[10] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1a[0] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1a[1] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1a[2] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1a[3] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1a[4] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1a[5] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[0] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[1] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[2] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[3] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[4] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[5] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[6] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[7] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[8] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[9] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[10] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[11] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[12] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[13] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[14] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[15] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.\gpio_defaults_block_0[0] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.\gpio_defaults_block_0[1] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.\gpio_defaults_block_2[0] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.\gpio_defaults_block_2[1] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.\gpio_defaults_block_2[2] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_5) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_6) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_7) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_8) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_9) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_10) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_11) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_12) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_13) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_14) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_15) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_16) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_17) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_18) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_19) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_20) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_21) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_22) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_23) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_24) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_25) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_26) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_27) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_28) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_29) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_30) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_31) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_32) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_33) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_34) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_35) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_36) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_37) ;
		end
	`endif 

	initial begin
		$dumpfile("lacerta.vcd");
		$dumpvars(0, lacerta_tb);
	end


	initial begin
		RSTB <= 1'b0;
		CSB  <= 1'b1;		// Force CSB high
		#2000;
		RSTB <= 1'b1;	    	// Release reset
		#3_00_000;
		CSB = 1'b0;		// CSB can be released
	end

	initial begin		// Power-up sequence
		power1 <= 1'b0;
		power2 <= 1'b0;
		power3 <= 1'b0;
		power4 <= 1'b0;
		#100;
		power1 <= 1'b1;
		#100;
		power2 <= 1'b1;
		#100;
		power3 <= 1'b1;
		#100;
		power4 <= 1'b1;
	end



	wire flash_csb;
	wire flash_clk;
	wire flash_io0;
	wire flash_io1;

	wire VDD3V3;
	wire VDD1V8;
	wire VSS;
	
	assign VDD3V3 = power1;
	assign VDD1V8 = power2;
	assign VSS = 1'b0;

	caravel uut (
		.vddio	  (VDD3V3),
		.vddio_2  (VDD3V3),
		.vssio	  (VSS),
		.vssio_2  (VSS),
		.vdda	  (VDD3V3),
		.vssa	  (VSS),
		.vccd	  (VDD1V8),
		.vssd	  (VSS),
		.vdda1    (VDD3V3),
		.vdda1_2  (VDD3V3),
		.vdda2    (VDD3V3),
		.vssa1	  (VSS),
		.vssa1_2  (VSS),
		.vssa2	  (VSS),
		.vccd1	  (VDD1V8),
		.vccd2	  (VDD1V8),
		.vssd1	  (VSS),
		.vssd2	  (VSS),
		.clock    (clock),
		.gpio     (gpio),
		.mprj_io  (mprj_io),
		.flash_csb(flash_csb),
		.flash_clk(flash_clk),
		.flash_io0(flash_io0),
		.flash_io1(flash_io1),
		.resetb	  (RSTB)
	);

	assign arst_n = RSTB;

	assign mprj_io[5] = uart_bfm_i.tx;
	assign uart_bfm_i.rx = mprj_io[6];

	assign {mprj_io[7], mprj_io[8], mprj_io[9], mprj_io[10], mprj_io[11], mprj_io[12], mprj_io[13], mprj_io[14],mprj_io[15],mprj_io[16],mprj_io[17],mprj_io[18],mprj_io[19],mprj_io[20],mprj_io[21],mprj_io[22]} = sram_addr;
	
	assign sram_we_n = mprj_io[31];
	assign sram_oe_n = mprj_io[32];

	//wire tft_sck, tft_ss, tft_mosi, tft_dc, tft_res;

	assign tft_sck = mprj_io[33];
	assign tft_ss = mprj_io[34];
	assign tft_mosi = mprj_io[35];
	assign tft_dc = mprj_io[36];
	assign tft_res = mprj_io[37];


	spiflash #(
		.FILENAME("lacerta.hex")
	) spiflash (
		.csb(flash_csb),
		.clk(flash_clk),
		.io0(flash_io0),
		.io1(flash_io1),
		.io2(),			// not used
		.io3()			// not used
	);



	assign clk = clock; //eliminate the old clock and assign the new one



  // RTL paths

	`define TOP_PATH uut.chip_core.mprj	// uncomment for caravel
/*
	`define DIG_TOP_PATH dig_top_i
  `define MEM_SYS_PATH dig_top_i.mem_sys_i
  `define SCREEN_SYSTEM_PATH dig_top_i.screen_system_i
  `define SRAM_CTRL_PATH dig_top_i.sram_controller_i
  `define WB_MMAPED_PATH dig_top_i.wb_slave_memory_mapped_i
	`define WB_MEM_PORTS_PATH dig_top_i.wb_slave_to_mem_sys_ports_i
	`define COMM_ARB_DECODER_PATH dig_top_i.command_arbiter_decoder_i
	`define MASK_GEN_PATH dig_top_i.mask_generator_i*/

	`define DIG_TOP_PATH `TOP_PATH.dig_top
  `define MEM_SYS_PATH `TOP_PATH.dig_top.mem_sys_i
  `define SCREEN_SYSTEM_PATH `TOP_PATH.dig_top.screen_system_i
  `define SRAM_CTRL_PATH `TOP_PATH.dig_top.sram_controller_i
  `define WB_MMAPED_PATH `TOP_PATH.dig_top.wb_slave_memory_mapped_i
	`define WB_MEM_PORTS_PATH `TOP_PATH.dig_top.wb_slave_to_mem_sys_ports_i
	`define COMM_ARB_DECODER_PATH `TOP_PATH.dig_top.command_arbiter_decoder_i
	`define MASK_GEN_PATH `TOP_PATH.dig_top.mask_generator_i

	parameter TB_NUM_OBJECTS = 10;

	wire clk, arst_n; // clock and reset
  /*initial begin
    clk = 1'b0;
    arst_n = 1'b0;
      #302000ns;
    arst_n = 1'b1;
  end
	always #10ns clk = !clk; // 50MHz frecuency
*/
	// THIS IS THE DATA THAT SHOULD BE ISSUED TO THE TFT SCREEN FOR INITIALIZATION IN ORDER
	reg [9:0] tft_init_mem [SCREEN_INIT_MEM_SIZE];
	initial begin
		tft_init_mem[0] = {2'b10, 8'd20}; // 20 ms delay
		tft_init_mem[1] = {2'b10, 8'd120 }; // 120 ms delay
		tft_init_mem[2] = {2'b00, 8'h01 }; // SWRESET
		tft_init_mem[3] = {2'b10, 8'd150 }; // 150 ms delay
		tft_init_mem[4] = {2'b00, 8'h11 }; // SLPOUT
		tft_init_mem[5] = {2'b10, 8'd120 }; // 120 ms delay
		tft_init_mem[6] = {2'b00, 8'h3A }; // COLMOD
		tft_init_mem[7] = {2'b01, 8'h55 }; // RGB565
		tft_init_mem[8] = {2'b10, 8'd10 }; // 10 ms delay
		tft_init_mem[9] = {2'b00, 8'h36 }; // MADCTL
		tft_init_mem[10] = {2'b01, 8'hA8 }; // orientation
		tft_init_mem[11] = {2'b00, 8'h2A }; // CASET - we set value 319
		tft_init_mem[12] = {2'b01, 8'h00 }; // X start high byte
		tft_init_mem[13] = {2'b01, 8'h00 }; // X start end byte
		tft_init_mem[14] = {2'b01, 8'h01 }; // X end high byte
		tft_init_mem[15] = {2'b01, 8'h3F }; // X end end byte
		tft_init_mem[16] = {2'b00, 8'h2B }; // RASET - we set value 239
		tft_init_mem[17] = {2'b01, 8'h00 }; // X start high byte
		tft_init_mem[18] = {2'b01, 8'h00 }; // X start end byte
		tft_init_mem[19] = {2'b01, 8'h00 }; // X end high byte
		tft_init_mem[20] = {2'b01, 8'hEF }; // X end end byte
		tft_init_mem[21] = {2'b00, 8'h20 }; // INVOFF - all zeros is black, all ones is white
		tft_init_mem[22] = {2'b00, 8'h13 }; // NORON
		tft_init_mem[23] = {2'b10, 8'd10 }; // 10 ms delay
		tft_init_mem[24] = {2'b00, 8'h29 }; // DISPON
		tft_init_mem[25] = {2'b10, 8'd20 }; // 20 ms delay
		for(int i = 26; i < SCREEN_INIT_MEM_SIZE; i = i + 1) // NOP for all remaining slots
			tft_init_mem[i] = {10'd0}; // NOP
	end

	// THIS IS THE DATA THAT SHOULD BE ISSUED TO THE TFT SCREEN FOR WRITING SIDEBAR IN ORDER
	parameter TFT_SIDEBAR_COMMANDS_SIZE = 2*SIDEBAR_SIZE/*2 Bytes per pixel*/ + 
																				1/*CASET command*/ + 
																				4/*2 Bytes for frame_st_x, and 2 Bytes for frame_end_x*/ + 
																				1/*RASET command*/ + 
																				4 /*2 Bytes for frame_st_y, and 2 Bytes for frame_end_y*/ + 
																				1 /*RAMWR command*/;
	reg [7:0] tft_sidebar [TFT_SIDEBAR_COMMANDS_SIZE];
	initial begin
		tft_sidebar[0] = 8'h2A; // CASET command
		tft_sidebar[1] = ACTIVE_SCREEN_WIDTH[15:8]; // st_x high Byte - high Byte first
		tft_sidebar[2] = ACTIVE_SCREEN_WIDTH[7:0]; // st_x low Byte
		tft_sidebar[3] = ((SCREEN_WIDTH - 1) >> 8) & 8'hFF; // end_x high Byte - high Byte first
		tft_sidebar[4] = (SCREEN_WIDTH - 1) & 8'hFF; // end_x low Byte
		tft_sidebar[5] = 8'h2B; // RASET command
		tft_sidebar[6] = 8'h00; // st_y high Byte - high Byte first
		tft_sidebar[7] = 8'h00; // st_y low Byte
		tft_sidebar[8] = ((SCREEN_HEIGHT - 1) >> 8) & 8'hFF; // end_y high Byte - high Byte first
		tft_sidebar[9] = (SCREEN_HEIGHT - 1) & 8'hFF; // end_y low Byte
		tft_sidebar[10] = 8'h2C; // RAMWR command
		for(int i = 0; i < 2*SIDEBAR_SIZE; i = i + 1) begin // 2 Bytes per pixel
			tft_sidebar[i + 11] = $random;
		end
	end

	// THIS IS THE DATA THAT SHOULD BE ISSUED TO THE TFT SCREEN FOR WRITING THE ACTIVE AREA IN ORDER
	parameter TFT_ACTIVE_AREA_COMMANDS_SIZE = ACTIVE_SCREEN_WIDTH*SCREEN_HEIGHT/*1 Byte per pixel*/ + 
																				1/*CASET command*/ + 
																				4/*2 Bytes for frame_st_x, and 2 Bytes for frame_end_x*/ + 
																				1/*RASET command*/ + 
																				4 /*2 Bytes for frame_st_y, and 2 Bytes for frame_end_y*/ + 
																				1 /*RAMWR command*/;
	reg [7:0] tft_active_area [TFT_ACTIVE_AREA_COMMANDS_SIZE];
	initial begin
		tft_active_area[0] = 8'h2A; // CASET command
		tft_active_area[1] = 8'h00; // st_x high Byte - high Byte first
		tft_active_area[2] = 8'h00; // st_x low Byte
		tft_active_area[3] = ((ACTIVE_SCREEN_WIDTH - 1) >> 8) & 8'hFF; // end_x high Byte - high Byte first
		tft_active_area[4] = (ACTIVE_SCREEN_WIDTH - 1) & 8'hFF; // end_x low Byte
		tft_active_area[5] = 8'h2B; // RASET command
		tft_active_area[6] = 8'h00; // st_y high Byte - high Byte first
		tft_active_area[7] = 8'h00; // st_y low Byte
		tft_active_area[8] = ((SCREEN_HEIGHT - 1) >> 8) & 8'hFF; // end_y high Byte - high Byte first
		tft_active_area[9] = (SCREEN_HEIGHT - 1) & 8'hFF; // end_y low Byte
		tft_active_area[10] = 8'h2C; // RAMWR command
		for(int i = 0; i < ACTIVE_SCREEN_WIDTH*SCREEN_HEIGHT; i = i + 1) begin // 1 Byte per pixel
			tft_active_area[i + 11] = $random;
		end
	end

	// tb array to mimic sram
	reg [7:0] tb_sram [2**MAIN_MEM_ADDR_WIDTH];
	initial begin
		reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] tb_sram_addr;
		#1; // wait 1 timestep so for avoiding race condition with other threads
		for(int x = 0; x < ACTIVE_SCREEN_WIDTH; x = x + 1) begin
			for(int y = 0; y < SCREEN_HEIGHT; y = y + 1) begin
				tb_sram_addr = x + y*ACTIVE_SCREEN_WIDTH;
				tb_sram[tb_sram_addr] = tft_active_area[tb_sram_addr + 11];
			end
		end
		for(int i = ACTIVE_SCREEN_WIDTH*SCREEN_HEIGHT; i < (2**MAIN_MEM_ADDR_WIDTH); i = i + 1) begin // fill out the remaining memory with random data
				tb_sram[i] = $random;
		end
	end

  // uprocessor interface
  wire up_soft_reset;
	wire up_enable;


  // connections with caravel
  wire [WB_ADDR_WIDTH-1:0]     	wb_adr_i; // Address input
  wire [WB_DATA_WIDTH-1:0]     	wb_dat_i; // Data input
  wire [WB_DATA_WIDTH-1:0]     	wb_dat_o; // Data output
  wire                    			wb_we_i;  // Write enable
  wire [(WB_DATA_WIDTH/8)-1:0] 	wb_sel_i; // Byte select
  wire                      		wb_stb_i; // Strobe
  wire                      		wb_cyc_i; // Cycle valid
  wire                      		wb_ack_o;  // Acknowledge

  // connections with sram
  wire [MAIN_MEM_ADDR_WIDTH-1:0] sram_addr;
  wire [MAIN_MEM_DATA_WIDTH-1:0] sram_data_in;
  wire [MAIN_MEM_DATA_WIDTH-1:0] sram_data_out;
  wire [MAIN_MEM_DATA_WIDTH-1:0] sram_data_oeb;
  wire sram_oe_n;
  wire sram_we_n;

	wire tft_sck;
	wire tft_ss;
	wire tft_mosi;
	wire tft_dc;
	wire tft_res;

  wire [MAIN_MEM_DATA_WIDTH-1:0] sram_dq;
  assign sram_dq = sram_data_oeb ? 8'hzz : sram_data_out; 
  assign sram_data_in = sram_data_oeb ? sram_dq : 8'd0;
  
  // uart BFM
	uart_bfm uart_bfm_i ();

  // this task can be used to send a byte to lacerta through host uart interface
	task uart_write_mem;
		input [7:0] addr;
		input [31:0] data;

		int COMMAND_WRITE;
		COMMAND_WRITE = 1;
		uart_bfm_i.uart_send_byte(COMMAND_WRITE); // We are going to do a write operation
		uart_bfm_i.uart_send_byte(addr); // We are going to do a write operation
		for(int i = 0; i < 4; i++) begin
			uart_bfm_i.uart_send_byte(data>>(i*8)); // We are going to do a write operation
		end
	endtask

	function void check_sram_consistency();
		for(int i = 0; i < ACTIVE_SCREEN_WIDTH*SCREEN_HEIGHT; i = i + 1) begin
			assert(tb_sram[i] === CY7C1049GN_i.mem[i]) else $fatal(1, "ERROR: MEMORY MISMATCH, tb %2H, RTL %2H", tb_sram[i], CY7C1049GN_i.mem[i]);
		end
	endfunction

	task draw_horizontal_type;
		input [9:0] obj_width;
		input [9:0] obj_height;
		input [9:0] obj_value;
		input [MAIN_MEM_ADDR_WIDTH-1:0] st_x;
		input [MAIN_MEM_ADDR_WIDTH-1:0] st_y;

		reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] tb_sram_addr;
    uart_write_mem(8'h08, HORIZONTAL_INCREMENTAL_TYPE); // object type horizontal
    uart_write_mem(8'h09, obj_width); // object width
    uart_write_mem(8'h0A, obj_height); // object height
    uart_write_mem(8'h0B, st_x + st_y*ACTIVE_SCREEN_WIDTH); // object starting address
    uart_write_mem(8'h0D, st_x); // object starting x coordinate
    uart_write_mem(8'h0E, st_y); // object starting y coordinate
    uart_write_mem(8'h07, obj_value); // trigger drawing circuit and object value
		wait(`MASK_GEN_PATH.done);
		for(int x = 0; x < obj_width; x = x + 1) begin
			for(int y = 0; y < obj_height; y = y + 1) begin
				tb_sram_addr = x + y*ACTIVE_SCREEN_WIDTH;
				tb_sram[tb_sram_addr][7] = x <= obj_value;
			end
		end
		check_sram_consistency();
	endtask

	task draw_vertical_type;
		input [9:0] obj_width;
		input [9:0] obj_height;
		input [9:0] obj_value;
		input [MAIN_MEM_ADDR_WIDTH-1:0] st_x;
		input [MAIN_MEM_ADDR_WIDTH-1:0] st_y;

		reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] tb_sram_addr;
    uart_write_mem(8'h08, VERTICAL_INCREMENTAL_TYPE); // object type vertical
    uart_write_mem(8'h09, obj_width); // object width
    uart_write_mem(8'h0A, obj_height); // object height
    uart_write_mem(8'h0B, st_x + st_y*ACTIVE_SCREEN_WIDTH); // object starting address
    uart_write_mem(8'h0D, st_x); // object starting x coordinate
    uart_write_mem(8'h0E, st_y); // object starting y coordinate
    uart_write_mem(8'h07, obj_value); // trigger drawing circuit and object value
		wait(`MASK_GEN_PATH.done);
		for(int x = 0; x < obj_width; x = x + 1) begin
			for(int y = 0; y < obj_height; y = y + 1) begin
				tb_sram_addr = x + y*ACTIVE_SCREEN_WIDTH;
				tb_sram[tb_sram_addr][7] = y <= obj_value;
			end
		end
		check_sram_consistency();
	endtask

	task draw_graph_type;
		input [9:0] obj_width;
		input [9:0] obj_height;
		input [9:0] obj_value;
		input [MAIN_MEM_ADDR_WIDTH-1:0] st_x;
		input [MAIN_MEM_ADDR_WIDTH-1:0] st_y;

		reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] tb_sram_addr;
    uart_write_mem(8'h08, GRAPH_TYPE); // object type graph
    uart_write_mem(8'h09, obj_width); // object width
    uart_write_mem(8'h0A, obj_height); // object height
    uart_write_mem(8'h0B, st_x + st_y*ACTIVE_SCREEN_WIDTH); // object starting address
    uart_write_mem(8'h0D, st_x); // object starting x coordinate
    uart_write_mem(8'h0E, st_y); // object starting y coordinate
    uart_write_mem(8'h07, obj_value); // trigger drawing circuit and object value
		wait(`MASK_GEN_PATH.done);
		for(int x = (obj_width - 1); x >= 0 ; x = x - 1) begin
			for(int y = 0; y < obj_height; y = y + 1) begin
				tb_sram_addr = x + y*ACTIVE_SCREEN_WIDTH;
				if(x == (obj_width - 1)) begin
					tb_sram[tb_sram_addr][7] = y <= obj_value;
				end else begin
					tb_sram[tb_sram_addr][7] = tb_sram[tb_sram_addr + 1][7]; // graph are left shifted
				end
			end
		end
		check_sram_consistency();
	endtask

	task draw_mask_type;
		input [9:0] obj_width;
		input [9:0] obj_height;
		input [MAIN_MEM_ADDR_WIDTH-1:0] st_x;
		input [MAIN_MEM_ADDR_WIDTH-1:0] st_y;
		input [MAIN_MEM_ADDR_WIDTH-1:0] st_mask;

		reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] tb_sram_addr;
		reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] mask_cnt;
		mask_cnt = {MAIN_MEM_ADDR_WIDTH {1'b0}};
    uart_write_mem(8'h08, MASK_TYPE); // object type mask
    uart_write_mem(8'h09, obj_width); // object width
    uart_write_mem(8'h0A, obj_height); // object height
    uart_write_mem(8'h0B, st_x + st_y*ACTIVE_SCREEN_WIDTH); // object starting address
    uart_write_mem(8'h0B, st_mask); // mask starting address
    uart_write_mem(8'h0D, st_x); // object starting x coordinate
    uart_write_mem(8'h0E, st_y); // object starting y coordinate
    uart_write_mem(8'h07, 32'h0000_0000); // trigger drawing circuit, object value is don't care for this
		wait(`MASK_GEN_PATH.done);
		for(int x = 0; x < obj_width; x = x + 1) begin
			for(int y = 0; y < obj_height; y = y + 1) begin
				mask_cnt = mask_cnt + 1'b1;
				tb_sram_addr = x + y*ACTIVE_SCREEN_WIDTH;
				tb_sram[tb_sram_addr][7] = tb_sram_addr[st_mask + mask_cnt];
			end
		end
		check_sram_consistency();
	endtask

  // SRAM model
  CY7C1049GN CY7C1049GN_i (
    .A(sram_addr),     // Address (512K locations)
    .DQ(mprj_io[30:23]),    // Data bus
    .CE_n(1'b0),  // Chip Enable (active low)
    .OE_n(sram_oe_n),  // Output Enable (active low)
    .WE_n(sram_we_n)   // Write Enable (active low)
  );

/*  // lacerta digital top instance
  dig_top dig_top_i(
    .clk(clk), // gpio
    .arst_n(arst_n), // gpio
    
    // uprocessor interface
    .up_soft_reset(up_soft_reset), // caravel
		.up_enable(up_enable), // caravel
    
    // UART interface
    .rx(uart_bfm_i.tx), // gpio
    .tx(uart_bfm_i.rx), // gpio
      
    // Wishbone interface (caravel)
    .wb_adr_i(wb_adr_i), // Address input
    .wb_dat_i(wb_dat_i), // Data input
    .wb_dat_o(wb_dat_o), // Data output
    .wb_we_i(wb_we_i),  // Write enable
    .wb_sel_i(wb_sel_i), // Byte select
    .wb_stb_i(wb_stb_i), // Strobe
    .wb_cyc_i(wb_cyc_i), // Cycle valid
    .wb_ack_o(wb_ack_o),  // Acknowledge
    
    // SRAM interface
    .sram_addr(sram_addr), // gpio
    .sram_data_in(sram_data_in), // gpio
    .sram_data_out(sram_data_out), // gpio
    .sram_data_oeb(sram_data_oeb), // if 0 sram_data is output, if 1 sram_data is input
    .sram_oe_n(sram_oe_n), // gpio
    .sram_we_n(sram_we_n), // gpio
    
    // TFT ports
    .sck(tft_sck), // gpio - sck
    .ss(tft_ss), // gpio - cs
    .mosi(tft_mosi), // gpio - mosi
    // data/command send to tft screen
    .dc(tft_dc), // gpio - dc
    .res(tft_res) // gpio - reset
  );
*/
	reg [2:0] obj_type;
	reg [9:0] obj_width, obj_height, obj_value;
	reg [MAIN_MEM_ADDR_WIDTH-1:0] st_x, st_y, st_mask;

	initial begin // checkers thread
		int delay_cnt;
		reg tb_dc;
		reg [15:0] tb_color;
		reg [7:0] tb_color_byte;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ================================= checkers for verifying the initialization of the tft screen through uart commands ================================ //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		for(int i = 0; i < SCREEN_INIT_MEM_SIZE; i = i + 1) begin // we are checking that the actual tft_init_mem data is sent to the spi_master

			wait(`SCREEN_SYSTEM_PATH.tft_control_fsm_i.curr_state == 1); // we wait for initialize state to check
			
			@(posedge clk);
			if(`SCREEN_SYSTEM_PATH.tft_control_fsm_i.rom_type != 2'b10) begin // if not a delay type, we make sure that the data sent through spi is the actual data stored in the tb initialization memory

				@(posedge clk); // extra delay since tnsm_data is flopped
				assert({`SCREEN_SYSTEM_PATH.tft_control_fsm_i.rom_type, `SCREEN_SYSTEM_PATH.spi_master_i.tnsm_data} == tft_init_mem[i])
					$display("PASS: correct tft_init_mem data %4X for entry %0d was sent to spi_master", tft_init_mem[i], i);
				else
					$fatal(1, "ERROR: incorrect tft_init_mem data %4X, tnsm_data %4X for entry %0d was sent to spi_master", tft_init_mem[i], `SCREEN_SYSTEM_PATH.spi_master_i.tnsm_data, i);

			end else begin // if delay type, we make sure that the delay duration is as expected

				delay_cnt = 0;
				$display("delay encountered %0d", `SCREEN_SYSTEM_PATH.tft_control_fsm_i.rom_data);

				@(posedge clk); // add extra delay so we leave state

				while(`SCREEN_SYSTEM_PATH.tft_control_fsm_i.sfty_dly_done == 1'b0) begin
					@(posedge clk);
					delay_cnt = delay_cnt + 1'b1;
				end
				assert( delay_cnt >= (tft_init_mem[i][7:0]*`SCREEN_SYSTEM_PATH.tft_control_fsm_i.CLK_CYCLES_PER_MS))
					$display("PASS: correct delay %4d for entry %0d was measured", delay_cnt, i);
				else
					$fatal(1, "ERROR: incorrect delay tb %4d, tft_init_mem %4d for entry %0d was measured", delay_cnt, (tft_init_mem[i][7:0]*`SCREEN_SYSTEM_PATH.tft_control_fsm_i.CLK_CYCLES_PER_MS), i);
			end

			@(posedge clk);

		end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ============================= checkers for verifying the issuing of the sidebar of the tft screen through uart commands ============================ //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		wait(`SCREEN_SYSTEM_PATH.tft_control_fsm_i.ss_ld_sidebar == 1); // we wait for command_arbiter_decoder to trigger ss_ld_sidebar

		for(int i = 0; i < TFT_SIDEBAR_COMMANDS_SIZE; i = i + 1) begin

			wait(`SCREEN_SYSTEM_PATH.tft_control_fsm_i.tnsm == 1); // we wait for tft_control_fsm to trigger tnsm flag to spi_master
			@(posedge clk); // extra delay since tnsm is flopped
			if((i == 0) || (i == 5) || (i == 10)) // Byte transmitted is COMMAND type
				tb_dc = 1'b0;
			else
				tb_dc = 1'b1;

				assert((tft_dc == tb_dc) && (`SCREEN_SYSTEM_PATH.spi_master_i.tnsm_data == tft_sidebar[i]))
					$display("PASS: correct tft_sidebar data and dc %2X for entry %0d was sent to spi_master", tft_sidebar[i], i);
				else
					$fatal(1, "ERROR: incorrect tft_sidebar data %2X, tnsm_data %2X for entry %0d was sent to spi_master", tft_sidebar[i], `SCREEN_SYSTEM_PATH.spi_master_i.tnsm_data, i);
			wait(`SCREEN_SYSTEM_PATH.tft_control_fsm_i.tnsm == 0); // as there is a handshake mechanism between spi_master and tft_control_fsm, we have to wait for tnsm to be deasserted
			@(posedge clk); // safety extra delay
		end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// =========================== checkers for verifying the issuing of the active area of the tft screen through uart commands ========================== //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		wait(`SCREEN_SYSTEM_PATH.tft_control_fsm_i.fetch_frame == 1); // we wait for command_arbiter_decoder to trigger fetch_frame

		for(int i = 0; i < TFT_ACTIVE_AREA_COMMANDS_SIZE; i = i + 1) begin

			if(i < 11) begin // commands and window size sent to tft screen

				wait(`SCREEN_SYSTEM_PATH.tft_control_fsm_i.tnsm == 1); // we wait for tft_control_fsm to trigger tnsm flag to spi_master

				@(posedge clk); // extra delay since tnsm is flopped

				if((i == 0) || (i == 5) || (i == 10)) // Byte transmitted is COMMAND type
					tb_dc = 1'b0;
				else
					tb_dc = 1'b1;

				assert((tft_dc == tb_dc) && (`SCREEN_SYSTEM_PATH.spi_master_i.tnsm_data == tft_active_area[i]))
					$display("PASS: correct tft_active_area data and dc %2X for entry %0d was sent to spi_master", tft_active_area[i], i);
				else
					$fatal(1, "ERROR: incorrect tft_active_area data %2X, tnsm_data %2X for entry %0d was sent to spi_master", tft_active_area[i], `SCREEN_SYSTEM_PATH.spi_master_i.tnsm_data, i);

			end else begin // active screen pixels data

				tb_dc = 1'b1;

				for(int j = 0; j < (i < 11) ? 1 : 2; j = j + 1) begin // we have two bytes per pixel/color

					wait(`SCREEN_SYSTEM_PATH.tft_control_fsm_i.tnsm == 1); // we wait for tft_control_fsm to trigger tnsm flag to spi_master

					@(posedge clk); // extra delay since tnsm is flopped

					if(tft_active_area[i][7]) // if mask is on
						tb_color = `SCREEN_SYSTEM_PATH.color_mapping_table_i.color_map[tft_active_area[i][6:3]]; // we get the color from the index in on mask
					else
						tb_color = `SCREEN_SYSTEM_PATH.color_mapping_table_i.color_map[tft_active_area[i][2:0]]; // we get the color from the index in off mask

					if(j == 1) // odd
						tb_color_byte = tb_color[7:0]; // low byte last
					else
						tb_color_byte = tb_color[15:8]; // high byte first

						assert((tft_dc == tb_dc) && (`SCREEN_SYSTEM_PATH.spi_master_i.tnsm_data == tb_color_byte))
							$display("PASS: correct tft_active_area data and dc %2X for entry %0d was sent to spi_master", tb_color_byte, i);
						else
							$fatal(1, "ERROR: incorrect tft_active_area data %2X, tnsm_data %2X for entry %0d was sent to spi_master", tb_color_byte, `SCREEN_SYSTEM_PATH.spi_master_i.tnsm_data, i);

					wait(`SCREEN_SYSTEM_PATH.tft_control_fsm_i.tnsm == 0); // as there is a handshake mechanism between spi_master and tft_control_fsm, we have to wait for tnsm to be deasserted

					@(posedge clk); // safety extra delay

				end
			end
		end

	end

  initial begin // stimulus thread
		wait(arst_n);
		repeat(10) @(posedge clk);

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ========================================= start the initialization of the tft screen through uart commands ========================================= //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		for(int i = 0; i < SCREEN_INIT_MEM_SIZE; i = i + 1) begin
    	uart_write_mem(8'h13, {tft_init_mem[i], i[5:0]}); // send data to tft initialization memory
		end
    uart_write_mem(8'h11, 32'h0000_0001); // set SPI clock divider to 1
    uart_write_mem(8'h12, 32'h0000_0001); // initialize screen

		#500ms; // This delay is required as the tft initialization process include some delays in ms

		assert(`SCREEN_SYSTEM_PATH.tft_control_fsm_i.initialization_done) $display("PASS: initialization_done flag was correctly asserted"); else $fatal(1, "ERROR: initialization_done flag was not asserted on tft_control_fsm after tft initialization commands were sent");

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ============================================ send the sidebar to the tft screen through uart commands ========================================== //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    uart_write_mem(8'h00, 32'h0000_0000); // set wpg starting address to 0
    uart_write_mem(8'h01, SIDEBAR_SIZE*2); // set wpg burst length to SIDEBAR_SIZE * 2
    uart_write_mem(8'h02, 32'h0000_0000); // triggers wpg busy
		for(int i = 0; i < SIDEBAR_SIZE*2; i = i + 1) begin
    	uart_write_mem(8'h06, tft_sidebar[i + 11]); // send data to be written into the tft as the sidebar
		end
    uart_write_mem(8'h16, 32'h0000_0000); // triggers ss_ld_sidebar
		assert(`SCREEN_SYSTEM_PATH.tft_control_fsm_i.sidebar_ongoing) $display("PASS: sidebar_ongoing flag was correctly asserted"); else $fatal(1, "ERROR: sidebar_ongoing flag was not asserted on tft_control_fsm after sidebar writing commands were sent");
		#20ms;
		assert(!`SCREEN_SYSTEM_PATH.tft_control_fsm_i.sidebar_ongoing) $display("PASS: sidebar_ongoing flag was correctly deasserted"); else $fatal(1, "ERROR: sidebar_ongoing flag was not deasserted on tft_control_fsm after some time");
		assert(`SCREEN_SYSTEM_PATH.tft_control_fsm_i.rd_buff_empty && (~`SCREEN_SYSTEM_PATH.tft_control_fsm_i.rpg_busy)) $display("PASS: rd buffer is empty and rpg not busy after slidebar displaying"); else $fatal(1, "ERROR: rd buffer is not empty or rpg still busy after slidebar displaying");

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ======================================== send the color map values to the screen system through uart commands ====================================== //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		for(int i = 0; i < COLOR_MAP_NUM; i = i + 1) begin
			reg [15:0] color;
			color = $random;
    	uart_write_mem(8'h15, {color, i[3:0]}); // send data to the 
			for(int i = 0; i < 5; i = i + 1) @(posedge clk); // wait for some clocks cycles for color code to propagate down to color_mapping_table circuitry
			assert(`SCREEN_SYSTEM_PATH.color_mapping_table_i.color_map[i] == color) $display("PASS: color map index %0d was correctly written to 16'h%4h", i, color); else $fatal(1, "ERROR: color map index %0d was not correctly written to 16'h%4h", i, color);
		end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ============================================ send the active screen to the tft screen through uart commands ======================================== //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    uart_write_mem(8'h00, 32'h0000_0000); // set wpg starting address to 0
    uart_write_mem(8'h01, ACTIVE_SCREEN_WIDTH*SCREEN_HEIGHT); // set wpg burst length to active screen size
    uart_write_mem(8'h02, 32'h0000_0000); // triggers wpg busy
		for(int i = 0; i < ACTIVE_SCREEN_WIDTH*SCREEN_HEIGHT; i = i + 1) begin
    	uart_write_mem(8'h06, tft_active_area[i + 11]); // send data to be written into the tft as the sidebar
		end
		#1ms; // safety delay to finish the transmission of above

		// activate the tft_control_fsm to fetch all the active screen from sram memory and to send to tft screen
		uart_write_mem(8'h09, ACTIVE_SCREEN_WIDTH); // set the object width
  	uart_write_mem(8'h0A, SCREEN_HEIGHT); // set the object height
  	uart_write_mem(8'h0B, 0); // set the starting address to 0
  	uart_write_mem(8'h0D, 0); // set the starting x to 0
  	uart_write_mem(8'h0E, 0); // set the starting y to 0
  	uart_write_mem(8'h14, 0); // trigger the screen system
		repeat(5) @(posedge clk);
		assert(`SCREEN_SYSTEM_PATH.tft_control_fsm_i.busy) $display("PASS: tft_control_fsm was correctly set as busy as expected during full image loading"); else $fatal(1, "ERROR: tft_control_fsm was not correctly set as busy as expected during full image loading");
		#105ms;
		assert(!`SCREEN_SYSTEM_PATH.tft_control_fsm_i.busy) $display("PASS: tft_control_fsm was correctly set as not busy as expected during full image loading"); else $fatal(1, "ERROR: tft_control_fsm was not correctly set as not busy as expected during full image loading");

		assert(`SCREEN_SYSTEM_PATH.tft_control_fsm_i.rd_buff_empty && (~`SCREEN_SYSTEM_PATH.tft_control_fsm_i.rpg_busy)) $display("PASS: rd buffer is empty and rpg not busy after active area displaying"); else $fatal(1, "ERROR: rd buffer is not empty or rpg still busy after active area displaying");

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ============================================== send random objects with random values through uart commands ======================================== //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		for(int i = 0; i < TB_NUM_OBJECTS; i = i + 1) begin
			obj_type = obj_type + 1;
			if(obj_type > 4)
				obj_type = 0;
			obj_width = $urandom_range(3,100);
			obj_height = $urandom_range(3,100);
			obj_value = $urandom_range(3,100); // if value is greater than width/height, we just fill up the object, so this should be supported
			st_x = $urandom_range(0, ACTIVE_SCREEN_WIDTH - obj_width); // no overflow in x coordinate should happen
			st_y = $urandom_range(0, SCREEN_HEIGHT - obj_height); // no overflow in y coordinate should happen
			st_mask = $urandom_range(0, ACTIVE_SCREEN_WIDTH*SCREEN_HEIGHT - obj_width*obj_height); // no overflow in memory should happen
			case(obj_type)
				3'b001: begin
					draw_horizontal_type(obj_width, obj_height, obj_value, st_x, st_y);
					#1ms;
				end
				3'b010: begin
					draw_vertical_type(obj_width, obj_height, obj_value, st_x, st_y);
					#1ms;
				end
				3'b011: begin
					draw_graph_type(obj_width, obj_height, obj_value, st_x, st_y);
					#1ms;
				end
				3'b100: begin
					draw_mask_type(obj_width, obj_height, st_x, st_y, st_mask);
					#1ms;
				end
				default: begin
					draw_horizontal_type(obj_width, obj_height, obj_value, st_x, st_y);
					#1ms;
				end
			endcase
		end


  	uart_write_mem(8'h10, 0); // assert up_enable so caravel microprocessor start fetching the instructions
		#100us;
		assert(up_enable) $display("PASS: up_enable was correctly set as expected after issuing the uart command"); else $fatal(1, "ERROR: up_enable was not set as expected after issuing the uart command");

    $finish;
  end

	reg [7:0] byte_data;
	initial begin // thread to add a checker to verify spi master serialization
		forever begin
			wait(`SCREEN_SYSTEM_PATH.spi_master_i.tnsm && `SCREEN_SYSTEM_PATH.spi_master_i.tnsm_ack); // we sample the transmission data when tnsm_data is acknowledged by spi_master
			byte_data = `SCREEN_SYSTEM_PATH.spi_master_i.tnsm_data;
			for(int i = 0; i < 8; i = i + 1) begin
				@(posedge tft_sck); // for spi mode 0, we sample on positive edge of sck
				assert(byte_data[7 - i] == tft_mosi) else $fatal(1, "ERROR: incorrect serialized data on spi_master in screen_system"); // MSB first for tft spi
			end
		end
	end

	initial begin // timeout thread
		#30s;
		$fatal(1,"TIMEOUT FATAL ERROR");
		$finish;
	end

//`define VERIFICATION 0
//`define SVA 0
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////                                                                        wb_slave_memory_mapped checkers and coverage model                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//`ifdef VERIFICATION
//
//  /* test plan
//  1.- wishbone slave should only acknowledge when a valid request from wishbone master is active
//  2.- when a request from wishbone master is active, the slave must acknowledge in maximum configurable clock cycles
//  3.- acknowledge from wishbone slave must be single cycle
//  4.- address, data, and control signals must be stable while an active master request is not acknowledged
//  5.- mem_we must be set when wishbone master request is a write request
//  6.- mem_we must not be set when wishbone master request is a read request
//  7.- wb_cyc_i, and wb_stb_i can only be cleared by wb_ack_o, there can not be two overlapping requests
//	8.- mem_waddr, mem_wdata, and mem_wmask must be correctly when wishbone master request is a write request
//	9.- mem_raddr must be correctly when wishbone master request is a read request
//	10.- wb_dat_o must reflect the data coming from memory when wishbone master read request finishes
//	11.- mem_wr_data_ack can only be set if a wishbone write operation is ongoing
//	12.- mem_rdy can only be set if a wishbone read operation is ongoing
//  */
//  
//  parameter MAX_ACK_CYCLES = 3; // maximum allowed cycles for an ongoing wishbone request
//  wire verbose;
//  assign verbose = 1;
//  
//  `ifdef SVA
//  
//    // 1. wishbone slave should only acknowledge when a valid request from wishbone master is active
//    wb_slave_memory_mapped_acknowledge_only_if_wb_req_ongoing: assert property (@(posedge clk) disable iff(`WB_MMAPED_PATH.wb_rst_i || `WB_MMAPED_PATH.up_soft_reset) `WB_MMAPED_PATH.wb_ack_o |-> `WB_MMAPED_PATH.wb_cyc_i && `WB_MMAPED_PATH.wb_stb_i);
//  
//    // 2.- when a request from wishbone master is active, the slave must acknowledge in maximum configurable clock cycles
//    acknowledge_in_max_three_cycles: assert property (@(posedge clk) disable iff(`WB_MMAPED_PATH.wb_rst_i || `WB_MMAPED_PATH.up_soft_reset) $rose(`WB_MMAPED_PATH.wb_cyc_i && `WB_MMAPED_PATH.wb_stb_i) |-> ##[0 : MAX_ACK_CYCLES] `WB_MMAPED_PATH.wb_ack_o);
//  
//    // 3.- acknowledge from wishbone slave must be single cycle
//    wb_slave_memory_mapped_wb_ack_o_must_be_single_cycle: assert property (@(posedge clk) disable iff(`WB_MMAPED_PATH.wb_rst_i || `WB_MMAPED_PATH.up_soft_reset) `WB_MMAPED_PATH.wb_ack_o |=> !`WB_MMAPED_PATH.wb_ack_o);
//  
//    // 4.- address, data, and control wishbone signals must be stable while an active master request is not acknowledged
//    wb_slave_memory_mapped_data_address_and_control_stable_while_req_ongoing: assert property (@(posedge clk) disable iff(`WB_MMAPED_PATH.wb_rst_i || `WB_MMAPED_PATH.up_soft_reset) `WB_MMAPED_PATH.wb_cyc_i && `WB_MMAPED_PATH.wb_stb_i |=> $stable({`WB_MMAPED_PATH.wb_cyc_i, `WB_MMAPED_PATH.wb_stb_i, `WB_MMAPED_PATH.wb_adr_i, `WB_MMAPED_PATH.wb_dat_i, `WB_MMAPED_PATH.wb_we_i, `WB_MMAPED_PATH.wb_sel_i}) || $past(`WB_MMAPED_PATH.wb_ack_o));
//  
//    // 5.- mem_we must be set, and mem_re must not be set when wishbone master request is a write request
//    wb_slave_memory_mapped_mem_we_must_be_set_on_wishbone_write_requests: assert property (@(posedge clk) disable iff(`WB_MMAPED_PATH.wb_rst_i || `WB_MMAPED_PATH.up_soft_reset) $rose(`WB_MMAPED_PATH.wb_cyc_i && `WB_MMAPED_PATH.wb_stb_i && `WB_MMAPED_PATH.wb_we_i) |=> `WB_MMAPED_PATH.mem_we && (!`WB_MMAPED_PATH.mem_re));
//  
//    // 6.- mem_we must not be set when wishbone master request is a read request
//    wb_slave_memory_mapped_mem_we_must_not_be_set_on_wishbone_read_requests: assert property (@(posedge clk) disable iff(`WB_MMAPED_PATH.wb_rst_i || `WB_MMAPED_PATH.up_soft_reset) $rose(`WB_MMAPED_PATH.wb_cyc_i && `WB_MMAPED_PATH.wb_stb_i) && (!`WB_MMAPED_PATH.wb_we_i) |=> `WB_MMAPED_PATH.mem_re && (!`WB_MMAPED_PATH.mem_we));
//  
//    // 7.- wb_cyc_i, and wb_stb_i can only be cleared by wb_ack_o, there can not be two overlapping requests
//    wb_slave_memory_mapped_mem_we_must_not_be_two_overlapping_wb_requests: assert property (@(posedge clk) disable iff(`WB_MMAPED_PATH.wb_rst_i || `WB_MMAPED_PATH.up_soft_reset) $fell(`WB_MMAPED_PATH.wb_cyc_i || `WB_MMAPED_PATH.wb_stb_i) |-> $past(`WB_MMAPED_PATH.wb_ack_o));
//
//    // 8.- mem_waddr, mem_wdata, and mem_wmask must be correctly when wishbone master request is a write request
//    wb_slave_memory_mapped_correct_addr_data_on_wishbone_write_requests: assert property (@(posedge clk) disable iff(`WB_MMAPED_PATH.wb_rst_i || `WB_MMAPED_PATH.up_soft_reset) $rose(`WB_MMAPED_PATH.wb_cyc_i && `WB_MMAPED_PATH.wb_stb_i && `WB_MMAPED_PATH.wb_we_i) |=> (`WB_MMAPED_PATH.mem_waddr == `WB_MMAPED_PATH.wb_adr_i) && (`WB_MMAPED_PATH.mem_wdata == `WB_MMAPED_PATH.wb_dat_i) && (`WB_MMAPED_PATH.mem_wmask == `WB_MMAPED_PATH.wb_sel_i));
//  
//    // 9.- mem_raddr must be correctly when wishbone master request is a read request
//    wb_slave_memory_mapped_correct_addr_data_on_wishbone_read_requests: assert property (@(posedge clk) disable iff(`WB_MMAPED_PATH.wb_rst_i || `WB_MMAPED_PATH.up_soft_reset) $rose(`WB_MMAPED_PATH.wb_cyc_i && `WB_MMAPED_PATH.wb_stb_i && (!`WB_MMAPED_PATH.wb_we_i)) |=> (`WB_MMAPED_PATH.mem_raddr == `WB_MMAPED_PATH.wb_adr_i));
//  
//    // 10.- wb_dat_o must reflect the data coming from memory when wishbone master read request finishes
//    wb_slave_memory_mapped_correct_wb_dat_o_on_wishbone_read_requests: assert property (@(posedge clk) disable iff(`WB_MMAPED_PATH.wb_rst_i || `WB_MMAPED_PATH.up_soft_reset) $rose(`WB_MMAPED_PATH.wb_cyc_i && `WB_MMAPED_PATH.wb_stb_i && (!`WB_MMAPED_PATH.wb_we_i)) |-> ##[0 : MAX_ACK_CYCLES] `WB_MMAPED_PATH.mem_rdy |=> (`WB_MMAPED_PATH.wb_dat_o == $past(`WB_MMAPED_PATH.mem_rdata)));
//  
//    // 11.- mem_wr_data_ack can only be set if a wishbone write operation is ongoing
//    wb_slave_memory_mapped_mem_wr_data_ack_can_be_set_only_on_wishbone_write_requests: assert property (@(posedge clk) disable iff(`WB_MMAPED_PATH.wb_rst_i || `WB_MMAPED_PATH.up_soft_reset) `WB_MMAPED_PATH.mem_wr_data_ack |-> `WB_MMAPED_PATH.wb_cyc_i && `WB_MMAPED_PATH.wb_stb_i && `WB_MMAPED_PATH.wb_we_i);
//  
//    // 12.- mem_rdy can only be set if a wishbone read operation is ongoing
//    wb_slave_memory_mapped_mem_rdy_can_be_set_only_on_wishbone_read_requests: assert property (@(posedge clk) disable iff(`WB_MMAPED_PATH.wb_rst_i || `WB_MMAPED_PATH.up_soft_reset) `WB_MMAPED_PATH.mem_rdy |-> `WB_MMAPED_PATH.wb_cyc_i && `WB_MMAPED_PATH.wb_stb_i && (!`WB_MMAPED_PATH.wb_we_i));
//  
//  
//  `else
//  
//  /*
//  Can you convert all these assertions to verilog checkers and be compatible wih icarus verilog, give me the code for them so I can just paste in my testbench, assume MAX_ACK_CYCLES is already declared and defined, also add a verbose signal to turn on and off the $display, verbose is also declared and defined elsewhere,
//  the clock signal is wb_clk_i, and we have two synchronous reset signals, wb_rst_i, and up_soft_reset, use only small letters, and add wb_slave_memory_mapped_ as a prefix on the $error and $display messages.
//  Declare all the required variables at the beggining of the code, and put the auxiliary logic, and checkers below that. Do not use $past, $fell, nor $rose.
//    // 1. wishbone slave should only acknowledge when a valid request from wishbone master is active
//    wb_slave_memory_mapped_acknowledge_only_if_wb_req_ongoing: (assert property @(posedge wb_clk_i) wb_ack_o |-> wb_cyc_i && wb_stb_i);
//    // 2.- when a request from wishbone master is active, the slave must acknowledge in three clock cycles
//    wb_slave_memory_mapped_acknowledge_in_max_three_cycles: (assert property @(posedge wb_clk_i) $rose(wb_cyc_i && wb_stb_i) |-> ##[0 : MAX_ACK_CYCLES] wb_ack_o);
//    // 3.- acknowledge from wishbone slave must be single cycle
//    wb_slave_memory_mapped_wb_ack_o_must_be_single_cycle: (assert property @(posedge wb_clk_i) wb_ack_o |=> !wb_ack_o);
//    // 4.- address, data, and control signals must be stable while an active master request is not acknowledged
//    wb_slave_memory_mapped_data_address_and_control_stable_while_req_ongoing: (assert property @(posedge wb_clk_i) wb_cyc_i && wb_stb_i |=> $stable({wb_cyc_i, wb_stb_i, wb_adr_i, wb_dat_i, wb_we_i, wb_sel_i}) || wb_ack_o);
//    // 5.- mem_we must be set when wishbone master request is a write request
//    wb_slave_memory_mapped_mem_we_must_be_set_on_wishbone_write_requests: (assert property @(posedge wb_clk_i) $rose(wb_cyc_i && wb_stb_i && wb_we_i) |=> mem_we);
//    // 6.- mem_we must not be set when wishbone master request is a read request
//    wb_slave_memory_mapped_mem_we_must_not_be_set_on_wishbone_read_requests: (assert property @(posedge wb_clk_i) $rose(wb_cyc_i && wb_stb_i) && (!wb_we_i) |=> !mem_we);
//    // 7.- wb_cyc_i, and wb_stb_i can only be cleared by wb_ack_o, there can not be two overlapping requests
//    wb_slave_memory_mapped_mem_we_must_not_be_two_overlapping_wb_requests: (assert property @(posedge wb_clk_i) $fell(wb_cyc_i || wb_stb_i) |-> $past(wb_ack_o));
//  
//  The ports list of the  module where this checkers are to be connected, is below:
//  
//  module wb_slave_memory_mapped #(
//    parameter DATA_WIDTH = 32, // Data width in bits
//    parameter ADDR_WIDTH = 32  // Address width in bits
//  )(
//    input wire wb_clk_i, // System clock
//    input wire wb_rst_i, // Synchronous reset (active high)
//    input wire up_soft_reset,
//  
//    // Wishbone interface
//    input wire [ADDR_WIDTH-1:0] wb_adr_i, // Address input
//    input wire [DATA_WIDTH-1:0] wb_dat_i, // Data input
//    output reg [DATA_WIDTH-1:0] wb_dat_o, // Data output
//    input wire wb_we_i,  // Write enable
//    input wire [(DATA_WIDTH/8)-1:0] wb_sel_i, // Byte select
//    input wire wb_stb_i, // Strobe
//    input wire wb_cyc_i, // Cycle valid
//    output reg wb_ack_o  // Acknowledge
//  );
//  */
//  
//  `endif
//
//`endif
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////                                                                        wb_slave_to_mem_sys_ports checkers and coverage model                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//`ifdef VERIFICATION
//
//	/* test plan
//	1.- wishbone slave should only acknowledge when a valid request from wishbone master is active
//	2.- acknowledge from wishbone slave must be single cycle
//	3.- address, data, and control signals must be stable while an active master request is not acknowledged
//	4.- wpg_busy must be set only when wishbone master request is a write request, and remain set until wpg_ack is set
//	5.- wpg_busy must remain set until wpg_ack is set
//	6.- rpg_busy must be set only when wishbone master request is a read request, and remain set until rpg_ack is set
//	7.- rpg_busy must remain set until rpg_ack is set
//	8.- wb_cyc_i, and wb_stb_i can only be cleared by wb_ack_o, there can not be two overlapping requests
//	9.- up_en must not change while either a read or write process is ongoing
//	10.- up_soft_reset must not change while either a read or write process is ongoing
//	11.- wpg_st_addr, wpg_burst_length, and wr_buff_wdata must be correctly set when wishbone master request is a write request
//	12.- wpg_st_addr, wpg_burst_length, and wr_buff_wdata must remain stable until wpg_ack is set
//	13.- rpg_st_addr, and rpg_burst_length must be correctly set when wishbone master request is a read request
//	14.- rpg_st_addr, and rpg_burst_length must remain stable until rpg_ack is set
//	13.- wr_buff_wren must be set only when wishbone master request is a write request, and can be set only once per write request
//	14.- rd_buff_rden must be set only when wishbone master request is a read request, and must be set NUM_ACCESSES times per read request
//	15.- rpg_ack can be set only when a master read operation is ongoing
//	16.- wpg_ack can be set only when a master write operation is ongoing
//	17.- wishbone read operation must finish when rpg_ack is set
//	18.- wishbone write operation must finish when wpg_ack is set
//	19.- if no wishbone read operation is ongoing, read buffer must be empty
//	20.- when a wishbone read operation finishes, rd_buff_rdata must reflect the correct data sent by memory system
//	21.- wishbone read or write operation can start only if microprocessor is enabled
//	22.- when a wishbone read operation finishes, rd_buff_rdata must reflect the correct data sent by memory system
//	23.- wishbone read or write operation can start only if microprocessor is enabled
//	*/
//	
//	`ifdef SVA
//	
//	  // 1. wishbone slave should only acknowledge when a valid request from wishbone master is active
//	  wb_slave_to_mem_sys_ports_acknowledge_only_if_wb_req_ongoing: assert property (@(posedge clk) disable iff(`WB_MEM_PORTS_PATH.wb_rst_i || `WB_MEM_PORTS_PATH.up_soft_reset) `WB_MEM_PORTS_PATH.wb_ack_o |-> `WB_MEM_PORTS_PATH.wb_cyc_i && `WB_MEM_PORTS_PATH.wb_stb_i);
//	
//	  // 2.- acknowledge from wishbone slave must be single cycle
//	  wb_slave_to_mem_sys_ports_wb_ack_o_must_be_single_cycle: assert property (@(posedge clk) disable iff(`WB_MEM_PORTS_PATH.wb_rst_i || `WB_MEM_PORTS_PATH.up_soft_reset) `WB_MEM_PORTS_PATH.wb_ack_o |=> !`WB_MEM_PORTS_PATH.wb_ack_o);
//	
//	  // 3.- address, data, and control signals must be stable while an active master request is not acknowledged
//	  wb_slave_to_mem_sys_ports_data_address_and_control_stable_while_req_ongoing: assert property (@(posedge clk) disable iff(`WB_MEM_PORTS_PATH.wb_rst_i || `WB_MEM_PORTS_PATH.up_soft_reset) `WB_MEM_PORTS_PATH.wb_cyc_i && `WB_MEM_PORTS_PATH.wb_stb_i |=> $stable({`WB_MEM_PORTS_PATH.wb_cyc_i, `WB_MEM_PORTS_PATH.wb_stb_i, `WB_MEM_PORTS_PATH.wb_adr_i, `WB_MEM_PORTS_PATH.wb_dat_i, `WB_MEM_PORTS_PATH.wb_we_i, `WB_MEM_PORTS_PATH.wb_sel_i}) || $past(`WB_MEM_PORTS_PATH.wb_ack_o));
//	
//	  // 4.- wpg_busy must be set only when wishbone master request is a write request
//	  wb_slave_to_mem_sys_ports_wpg_busy_must_be_set_on_wishbone_write_requests: assert property (@(posedge clk) disable iff(`WB_MEM_PORTS_PATH.wb_rst_i || `WB_MEM_PORTS_PATH.up_soft_reset) $rose(`WB_MEM_PORTS_PATH.wb_cyc_i && `WB_MEM_PORTS_PATH.wb_stb_i && `WB_MEM_PORTS_PATH.wb_we_i && `WB_MEM_PORTS_PATH.up_en) |=> `WB_MEM_PORTS_PATH.wpg_busy && (!`WB_MEM_PORTS_PATH.rpg_busy));
//
//	  // 5.- wpg_busy must remain set until wpg_ack is set
//	  wb_slave_to_mem_sys_ports_wpg_busy_must_remain_set_until_wpg_ack: assert property (@(posedge clk) disable iff(`WB_MEM_PORTS_PATH.wb_rst_i || `WB_MEM_PORTS_PATH.up_soft_reset) `WB_MEM_PORTS_PATH.wpg_busy |=> `WB_MEM_PORTS_PATH.wpg_busy ^ $past(`WB_MEM_PORTS_PATH.wpg_ack));
//	
//	  // 6.- rpg_busy must be set only when wishbone master request is a read request
//	  wb_slave_to_mem_sys_ports_rpg_busy_must_be_set_on_wishbone_read_requests: assert property (@(posedge clk) disable iff(`WB_MEM_PORTS_PATH.wb_rst_i || `WB_MEM_PORTS_PATH.up_soft_reset) $rose(`WB_MEM_PORTS_PATH.wb_cyc_i && `WB_MEM_PORTS_PATH.wb_stb_i) && (!`WB_MEM_PORTS_PATH.wb_we_i) |=> `WB_MEM_PORTS_PATH.rpg_busy && (!`WB_MEM_PORTS_PATH.wpg_busy));
//
//	  // 7.- rpg_busy must remain set until rpg_ack is set
//	  wb_slave_to_mem_sys_ports_rpg_busy_must_remain_set_until_rpg_ack: assert property (@(posedge clk) disable iff(`WB_MEM_PORTS_PATH.wb_rst_i || `WB_MEM_PORTS_PATH.up_soft_reset) `WB_MEM_PORTS_PATH.rpg_busy |=> `WB_MEM_PORTS_PATH.rpg_busy ^ $past(`WB_MEM_PORTS_PATH.rpg_ack));
//
//	  // 8.- wb_cyc_i, and wb_stb_i can only be cleared by wb_ack_o, there can not be two overlapping requests
//	  wb_slave_to_mem_sys_ports_mem_we_must_not_be_two_overlapping_wb_requests: assert property (@(posedge clk) disable iff(`WB_MEM_PORTS_PATH.wb_rst_i || `WB_MEM_PORTS_PATH.up_soft_reset) $fell(`WB_MEM_PORTS_PATH.wb_cyc_i || `WB_MEM_PORTS_PATH.wb_stb_i) |-> $past(`WB_MEM_PORTS_PATH.wb_ack_o));
//	
//	  // 9.- up_en must not change while either a read or write process is ongoing
//	  wb_slave_to_mem_sys_ports_up_en_not_change_while_read_write_ongoing: assert property (@(posedge clk) disable iff(`WB_MEM_PORTS_PATH.wb_rst_i || `WB_MEM_PORTS_PATH.up_soft_reset) `WB_MEM_PORTS_PATH.rd_pending || `WB_MEM_PORTS_PATH.wr_pending || (`WB_MEM_PORTS_PATH.wb_cyc_i && `WB_MEM_PORTS_PATH.wb_stb_i)  |-> $stable(`WB_MEM_PORTS_PATH.up_en));
//	
//	  // 10.- up_soft_reset must not change while either a read or write process is ongoing
//	  wb_slave_to_mem_sys_ports_up_soft_reset_not_change_while_read_write_ongoing: assert property (@(posedge clk) disable iff(`WB_MEM_PORTS_PATH.wb_rst_i) `WB_MEM_PORTS_PATH.rd_pending || `WB_MEM_PORTS_PATH.wr_pending || (`WB_MEM_PORTS_PATH.wb_cyc_i && `WB_MEM_PORTS_PATH.wb_stb_i)  |-> $stable(`WB_MEM_PORTS_PATH.up_soft_reset));
//
//	  // 11.- wpg_st_addr, wpg_burst_length, and wr_buff_wdata must be correctly set when wishbone master request is a write request
//	  wb_slave_to_mem_sys_ports_wpg_addr_burst_length_wdata_correctly_set_on_wishbone_write_requests: assert property (@(posedge clk) disable iff(`WB_MEM_PORTS_PATH.wb_rst_i || `WB_MEM_PORTS_PATH.up_soft_reset) $rose(`WB_MEM_PORTS_PATH.wb_cyc_i && `WB_MEM_PORTS_PATH.wb_stb_i && `WB_MEM_PORTS_PATH.wb_we_i && `WB_MEM_PORTS_PATH.up_en) |=> (`WB_MEM_PORTS_PATH.wpg_st_addr == `WB_MEM_PORTS_PATH.wb_adr_i[MAIN_MEM_ADDR_WIDTH - 1 : 0]) && (`WB_MEM_PORTS_PATH.wpg_burst_length == 1) && (`WB_MEM_PORTS_PATH.wr_buff_wdata == `WB_MEM_PORTS_PATH.wb_dat_i[MAIN_MEM_DATA_WIDTH - 1 : 0]));
//
//	  // 12.- wpg_st_addr, wpg_burst_length, and wr_buff_wdata must remain stable until wpg_ack is set
//	  wb_slave_to_mem_sys_ports_wpg_addr_burst_length_wdata_must_remain_stable_until_wpg_ack: assert property (@(posedge clk) disable iff(`WB_MEM_PORTS_PATH.wb_rst_i || `WB_MEM_PORTS_PATH.up_soft_reset) `WB_MEM_PORTS_PATH.wpg_busy |=> $stable({`WB_MEM_PORTS_PATH.wpg_st_addr, `WB_MEM_PORTS_PATH.wpg_burst_length, `WB_MEM_PORTS_PATH.wr_buff_wdata}));
//
//	  // 13.- rpg_st_addr, and rpg_burst_length must be correctly set when wishbone master request is a read request
//	  wb_slave_to_mem_sys_ports_rpg_addr_burst_length_correctly_set_on_wishbone_read_requests: assert property (@(posedge clk) disable iff(`WB_MEM_PORTS_PATH.wb_rst_i || `WB_MEM_PORTS_PATH.up_soft_reset) $rose(`WB_MEM_PORTS_PATH.wb_cyc_i && `WB_MEM_PORTS_PATH.wb_stb_i && (!`WB_MEM_PORTS_PATH.wb_we_i)) |=> (`WB_MEM_PORTS_PATH.rpg_st_addr == `WB_MEM_PORTS_PATH.wb_adr_i[MAIN_MEM_ADDR_WIDTH - 1 : 0]) && (`WB_MEM_PORTS_PATH.rpg_burst_length == `WB_MEM_PORTS_PATH.NUM_ACCESSES));
//
//	  // 14.- rpg_st_addr, and rpg_burst_length must remain stable until rpg_ack is set
//	  wb_slave_to_mem_sys_ports_rpg_addr_burst_length_must_remain_stable_until_rpg_ack: assert property (@(posedge clk) disable iff(`WB_MEM_PORTS_PATH.wb_rst_i || `WB_MEM_PORTS_PATH.up_soft_reset) `WB_MEM_PORTS_PATH.rpg_busy |=> $stable({`WB_MEM_PORTS_PATH.rpg_st_addr, `WB_MEM_PORTS_PATH.rpg_burst_length}));
//
//	integer cnt_wr_buff_wren;
//	always@(posedge clk, negedge arst_n) begin
//		if(!arst_n) begin
//			cnt_wr_buff_wren <= 0;
//		end else begin
//			if(`WB_MEM_PORTS_PATH.wb_cyc_i && `WB_MEM_PORTS_PATH.wb_stb_i && `WB_MEM_PORTS_PATH.wb_we_i) begin
//				if(`WB_MEM_PORTS_PATH.wr_buff_wren)
//					cnt_wr_buff_wren <= cnt_wr_buff_wren + 1'b1;
//			end else begin
//				cnt_wr_buff_wren <= 0;
//			end
//		end
//	end
//
//	  // 15.- wr_buff_wren must be set only when wishbone master request is a write request, and can be set only once per write request
//	  wb_slave_to_mem_sys_ports_wr_buff_wren_set_only_once: assert property (@(posedge clk) disable iff(`WB_MEM_PORTS_PATH.wb_rst_i || `WB_MEM_PORTS_PATH.up_soft_reset) (`WB_MEM_PORTS_PATH.wb_cyc_i && `WB_MEM_PORTS_PATH.wb_stb_i && `WB_MEM_PORTS_PATH.wb_we_i && `WB_MMAPED_PATH.wb_ack_o) |-> cnt_wr_buff_wren == 1);
//
//	integer cnt_rd_buff_rden;
//	always@(posedge clk, negedge arst_n) begin
//		if(!arst_n) begin
//			cnt_rd_buff_rden <= 0;
//		end else begin
//			if(`WB_MEM_PORTS_PATH.wb_cyc_i && `WB_MEM_PORTS_PATH.wb_stb_i && (!`WB_MEM_PORTS_PATH.wb_we_i)) begin
//				if(`WB_MEM_PORTS_PATH.rd_buff_rden)
//					cnt_rd_buff_rden <= cnt_rd_buff_rden + 1'b1;
//			end else begin
//				cnt_rd_buff_rden <= 0;
//			end
//		end
//	end
//
//	  // 16.- rd_buff_rden must be set only when wishbone master request is a read request, and must be set NUM_ACCESSES times per read request
//	  wb_slave_to_mem_sys_ports_rd_buff_rden_set_num_accesses: assert property (@(posedge clk) disable iff(`WB_MEM_PORTS_PATH.wb_rst_i || `WB_MEM_PORTS_PATH.up_soft_reset) (`WB_MEM_PORTS_PATH.wb_cyc_i && `WB_MEM_PORTS_PATH.wb_stb_i && (!`WB_MEM_PORTS_PATH.wb_we_i) && `WB_MMAPED_PATH.wb_ack_o) |-> cnt_rd_buff_rden == `WB_MEM_PORTS_PATH.NUM_ACCESSES);
//
//	  // 17.- rpg_ack can be set only when a master read operation is ongoing
//	  wb_slave_to_mem_sys_ports_rpg_ack_only_if_read_ongoing: assert property (@(posedge clk) disable iff(`WB_MEM_PORTS_PATH.wb_rst_i || `WB_MEM_PORTS_PATH.up_soft_reset) `WB_MEM_PORTS_PATH.rpg_ack |-> `WB_MEM_PORTS_PATH.wb_cyc_i && `WB_MEM_PORTS_PATH.wb_stb_i && (!`WB_MEM_PORTS_PATH.wb_we_i));
//
//	  // 18.- wpg_ack can be set only when a master write operation is ongoing
//	  wb_slave_to_mem_sys_ports_wpg_ack_only_if_write_ongoing: assert property (@(posedge clk) disable iff(`WB_MEM_PORTS_PATH.wb_rst_i || `WB_MEM_PORTS_PATH.up_soft_reset) `WB_MEM_PORTS_PATH.wpg_ack |-> `WB_MEM_PORTS_PATH.wb_cyc_i && `WB_MEM_PORTS_PATH.wb_stb_i && `WB_MEM_PORTS_PATH.wb_we_i);
//
//	  // 19.- wishbone read operation must finish when rpg_ack is set
//	  wb_slave_to_mem_sys_ports_rd_operation_must_finish_on_rpg_ack: assert property (@(posedge clk) disable iff(`WB_MEM_PORTS_PATH.wb_rst_i || `WB_MEM_PORTS_PATH.up_soft_reset) `WB_MEM_PORTS_PATH.rpg_ack |-> ##[0:2] `WB_MEM_PORTS_PATH.wb_ack_o && (!`WB_MEM_PORTS_PATH.rd_pending));
//
//	  // 20.- wishbone write operation must finish when wpg_ack is set
//	  wb_slave_to_mem_sys_ports_wr_operation_must_finish_on_wpg_ack: assert property (@(posedge clk) disable iff(`WB_MEM_PORTS_PATH.wb_rst_i || `WB_MEM_PORTS_PATH.up_soft_reset) `WB_MEM_PORTS_PATH.wpg_ack |=> `WB_MEM_PORTS_PATH.wb_ack_o && (!`WB_MEM_PORTS_PATH.wr_pending));
//
//	  // 21.- if no wishbone read operation is ongoing, read buffer must be empty
//	  wb_slave_to_mem_sys_ports_rd_buff_empty_if_no_rd_ongoing: assert property (@(posedge clk) disable iff(`WB_MEM_PORTS_PATH.wb_rst_i || `WB_MEM_PORTS_PATH.up_soft_reset) (!(`WB_MEM_PORTS_PATH.wb_cyc_i && `WB_MEM_PORTS_PATH.wb_stb_i && (!`WB_MEM_PORTS_PATH.wb_we_i))) |-> `WB_MEM_PORTS_PATH.rd_buff_empty);
//
//		reg [WB_DATA_WIDTH - 1 : 0] tb_wb_mem_ports_rdata;
//		always@(posedge clk, negedge arst_n) begin
//			if(!arst_n) begin
//				tb_wb_mem_ports_rdata <= {WB_DATA_WIDTH{1'b0}};
//			end else begin
//				if(`WB_MEM_PORTS_PATH.wb_cyc_i && `WB_MEM_PORTS_PATH.wb_stb_i && (!`WB_MEM_PORTS_PATH.wb_we_i)) begin
//					if(`WB_MEM_PORTS_PATH.rd_buff_rden)
//						tb_wb_mem_ports_rdata <= {tb_wb_mem_ports_rdata[WB_DATA_WIDTH - MAIN_MEM_DATA_WIDTH - 1], `WB_MEM_PORTS_PATH.rd_buff_rdata};
//				end
//			end
//		end
//
//	  // 22.- when a wishbone read operation finishes, rd_buff_rdata must reflect the correct data sent by memory system
//	  wb_slave_to_mem_sys_ports_correct_rd_buff_rdata_on_rd_finish: assert property (@(posedge clk) disable iff(`WB_MEM_PORTS_PATH.wb_rst_i || `WB_MEM_PORTS_PATH.up_soft_reset) (`WB_MEM_PORTS_PATH.wb_cyc_i && `WB_MEM_PORTS_PATH.wb_stb_i && (!`WB_MEM_PORTS_PATH.wb_we_i) && `WB_MMAPED_PATH.wb_ack_o) |-> `WB_MEM_PORTS_PATH.wb_dat_o == tb_wb_mem_ports_rdata);
//
//	  // 23.- wishbone read or write operation can start only if microprocessor is enabled
//	  wb_slave_to_mem_sys_ports_wb_read_write_operation_only_if_up_en: assert property (@(posedge clk) disable iff(`WB_MEM_PORTS_PATH.wb_rst_i) `WB_MEM_PORTS_PATH.wb_cyc_i && `WB_MEM_PORTS_PATH.wb_stb_i |-> ~`WB_MEM_PORTS_PATH.up_soft_reset);
//
//	`else
//	
//	`endif
//
//`endif
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////                                                                        vga_controller checkers and coverage model                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//`ifdef VERIFICATION
//
//	/* test plan
//	1.- rden can't be set if buffer empty flag is set
//	2.- if frame is active, rden must be set
//	3.- if rden is set, data coming from red, green, and blue, should be reflected into ored, ogreen, and oblue
//	4.- hsync_deact, hsync_act, vsync_deact, and vsync_act must have the correct value 
//	5.- h_sync must have the correct period for 640x480@60fps (hsync_act/hsync_deact)
//	6.- v_sync must have the correct period for 640x480@60fps (vsync_act/vsync_deact)
//	7.- blank must be set only when frame is active
//	8.- oclk must have a frequency of approximately 25 MHz
//	*/
//	
//	`ifdef SVA
//	
//	  // 1. rden can't be set if vga controller is not enabled, or buffer empty flag is set
//	  vga_controller_no_rden_if_not_enabled_or_buffer_empty: assert property (@(posedge clk) disable iff(~`VGA_CTRL_PATH.arst_n) `VGA_CTRL_PATH.rden |-> ~`VGA_CTRL_PATH.empty);
//	
//	  // 2. if frame is active, rden must be set, if frame is not active, rden must not be set
//	  vga_controller_rden_set_if_frame_is_active: assert property (@(posedge clk) disable iff(~`VGA_CTRL_PATH.arst_n) 1'b1 |-> (`VGA_CTRL_PATH.enable && `VGA_CTRL_PATH.h_sync && `VGA_CTRL_PATH.v_sync && `VGA_CTRL_PATH.clk_en) == `VGA_CTRL_PATH.rden);
//	
//	  // 3.- if rden is set, data coming from red, green, and blue, should be reflected into ored, ogreen, and oblue
//	  vga_controller_rgb_propagated_if_frame_is_active: assert property (@(posedge clk) disable iff(~`VGA_CTRL_PATH.arst_n) `VGA_CTRL_PATH.rden |-> (`VGA_CTRL_PATH.red === `VGA_CTRL_PATH.ored) && (`VGA_CTRL_PATH.green === `VGA_CTRL_PATH.ogreen) && (`VGA_CTRL_PATH.blue === `VGA_CTRL_PATH.oblue));
//	
//	  // 4.- hsync_deact, hsync_act, vsync_deact, and vsync_act must have the correct value 
//	  vga_controller_hsync_act_deact_vsync_deact_act_must_be_correct: assert property (@(posedge clk) disable iff(~`VGA_CTRL_PATH.arst_n) `VGA_CTRL_PATH.enable |-> (`VGA_CTRL_PATH.hsync_deact == H_SYNC_DEACT) && (`VGA_CTRL_PATH.hsync_act == H_SYNC_ACT) && (`VGA_CTRL_PATH.vsync_deact == V_SYNC_DEACT) && (`VGA_CTRL_PATH.vsync_act == V_SYNC_ACT));
//
//		reg [10 : 0] tb_hsync_act_cnt;
//		reg [9 : 0] tb_hsync_deact_cnt;
//		reg first_frame;
//		always@(posedge clk, negedge arst_n) begin
//			if(!arst_n) begin
//				tb_hsync_act_cnt <= 11'd0;
//				tb_hsync_deact_cnt <= 10'd0;
//				first_frame <= 1'b0;
//			end else begin
//				if(`VGA_CTRL_PATH.h_sync) begin
//					first_frame <= 1'b1; // as we are sampling when h_sync is low, it will be low at the power up, so we want to trigger the property until the first frame is seen
//					tb_hsync_deact_cnt <= 10'd0;
//					if(`VGA_CTRL_PATH.clk_en)
//						tb_hsync_act_cnt <= tb_hsync_act_cnt + 1'b1;
//				end else if(`VGA_CTRL_PATH.clk_en) begin
//					tb_hsync_deact_cnt <= tb_hsync_deact_cnt + 1'b1;
//					tb_hsync_act_cnt <= 11'd0;
//				end
//			end
//		end
//
//		// 5.- h_sync must have the correct period for 640x480@60fps (hsync_act/hsync_deact)
//	  vga_controller_hsync_correct_period: assert property (@(posedge clk) disable iff(~`VGA_CTRL_PATH.arst_n) $fell(`VGA_CTRL_PATH.h_sync) || $rose(`VGA_CTRL_PATH.h_sync) && first_frame |-> `VGA_CTRL_PATH.h_sync ? tb_hsync_deact_cnt == H_SYNC_DEACT : tb_hsync_act_cnt == H_SYNC_ACT);
//
//		reg [10 : 0] tb_vsync_act_cnt;
//		reg [9 : 0] tb_vsync_deact_cnt;
//		always@(posedge clk, negedge arst_n) begin
//			if(!arst_n) begin
//				tb_vsync_act_cnt <= 11'd0;
//				tb_vsync_deact_cnt <= 10'd0;
//			end else begin
//				if(`VGA_CTRL_PATH.v_sync && `VGA_CTRL_PATH.eor) begin
//					tb_vsync_deact_cnt <= 10'd0;
//					if(`VGA_CTRL_PATH.clk_en)
//						tb_vsync_act_cnt <= tb_vsync_act_cnt + 1'b1;
//				end else if(`VGA_CTRL_PATH.clk_en &&  `VGA_CTRL_PATH.eor) begin
//					tb_vsync_deact_cnt <= tb_vsync_deact_cnt + 1'b1;
//					tb_vsync_act_cnt <= 11'd0;
//				end
//			end
//		end
//	
//		// 6.- v_sync must have the correct period for 640x480@60fps (vsync_act/vsync_deact)
//	  vga_controller_vsync_correct_period: assert property (@(posedge clk) disable iff(~`VGA_CTRL_PATH.arst_n) $fell(`VGA_CTRL_PATH.v_sync) || $rose(`VGA_CTRL_PATH.v_sync) |-> `VGA_CTRL_PATH.v_sync ? tb_vsync_deact_cnt == V_SYNC_DEACT : tb_vsync_act_cnt == V_SYNC_ACT);
//
//		// 7.- blank must be set only when frame is active
//	  vga_controller_blank_only_when_frame_active: assert property (@(posedge clk) disable iff(~`VGA_CTRL_PATH.arst_n) `VGA_CTRL_PATH.v_sync && `VGA_CTRL_PATH.h_sync |-> `VGA_CTRL_PATH.blank);
//
//		// 8.- oclk must have a frequency of approximately 25 MHz
//		int vga_clk_period_cnt;
//		logic prev_vga_clk;
//		initial begin
//			prev_vga_clk = 1'b0;
//			vga_clk_period_cnt = 0;
//			forever begin
//				if(`VGA_CTRL_PATH.clk_en && !prev_vga_clk) begin
//					if(vga_clk_period_cnt != 0) // we do not trigger at the first time we see a positive edge of clk_en
//						assert(vga_clk_period_cnt == 40) else $error("failed vga_controller_correct_vga_clk_frequency assertion"); // period for 25 MHz is 40ns
//					vga_clk_period_cnt = 1;
//				end else if(vga_clk_period_cnt != 0) begin // we do not trigger at the first time we see a positive edge of clk_en
//					vga_clk_period_cnt = vga_clk_period_cnt + 1'b1;
//				end
//				prev_vga_clk = `VGA_CTRL_PATH.clk_en;
//				#1ns;
//			end
//		end
//
//	`else
//	
//	`endif
//
//
//`endif
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////                                                                        command_arbiter_decoder checkers and coverage model                                                                //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//`ifdef VERIFICATION
//
//	/* test plan
//	1.- when drw_inc_start is set, drawing object type must be in valid ranges, drawing object width, and drawing object height must be greater than MIN_OBJECT_WIDTH_HEIGHT
//	2.- when drw_inc_start is set, drw_inc_busy must change from 0 to 1
//	3.- data going to drawing circuit, must remain stable while drw_inc_busy is set
//	4.- drw_inc_busy can not be set for more than DRW_BUSY_TIMEOUT clock cycles (need to check the exact number of cycles - timeout checker)
//	5.- wb_slave_up_en must be set when uart write command is 'd18
//	6.- wb_slave_up_en can only be deasserted if no access transaction is ongoing from microprocessor to memory system
//	7.- up_soft_reset can only be set if no access transaction is ongoing from microprocessor to memory system
//	*/
//
//	localparam MIN_OBJECT_WIDTH_HEIGHT = 2;
//	localparam DRW_BUSY_TIMEOUT = 150000;
//	
//	`ifdef SVA
//	
//	  // 1. when drw_inc_start is set, drawing object type must be in valid ranges, drawing object width, and drawing object height must be greater than MIN_OBJECT_WIDTH_HEIGHT
//	  command_arbiter_decoder_valid_drawing_data_when_start: assert property (@(posedge clk) disable iff(~`COMM_ARB_DECODER_PATH.arst_n) `COMM_ARB_DECODER_PATH.drw_inc_start |-> (`COMM_ARB_DECODER_PATH.obj_type inside {`DRW_PATH.BOOLEAN_TYPE, `DRW_PATH.HORIZONTAL_INCREMENTAL_TYPE, `DRW_PATH.VERTICAL_INCREMENTAL_TYPE, `DRW_PATH.GRAPH_TYPE, `DRW_PATH.MASK_TYPE}) && (`COMM_ARB_DECODER_PATH.obj_width > MIN_OBJECT_WIDTH_HEIGHT) && (`COMM_ARB_DECODER_PATH.obj_height > MIN_OBJECT_WIDTH_HEIGHT));
//
//	  // 2.- when drw_inc_start is set, drw_inc_busy must change from 0 to 1
//	  command_arbiter_decoder_draw_busy_after_start: assert property (@(posedge clk) disable iff(~`COMM_ARB_DECODER_PATH.arst_n) `COMM_ARB_DECODER_PATH.drw_inc_start |=> $rose(`COMM_ARB_DECODER_PATH.drw_inc_busy));
//
//	  // 3.- data going to drawing circuit, must remain stable while drw_inc_busy is set
//	  command_arbiter_decoder_draw_data_stable_while_busy: assert property (@(posedge clk) disable iff(~`COMM_ARB_DECODER_PATH.arst_n) `COMM_ARB_DECODER_PATH.drw_inc_busy |-> $stable({`COMM_ARB_DECODER_PATH.obj_type, `COMM_ARB_DECODER_PATH.obj_width, `COMM_ARB_DECODER_PATH.obj_height, `COMM_ARB_DECODER_PATH.obj_st_pix, `COMM_ARB_DECODER_PATH.obj_st_mask, `COMM_ARB_DECODER_PATH.obj_value}));
//
//	  // 4.- drw_inc_busy can not be set for more than DRW_BUSY_TIMEOUT clock cycles (need to check the exact number of cycles - timeout checker)
//	  command_arbiter_decoder_draw_busy_timeout: assert property (@(posedge clk) disable iff(~`COMM_ARB_DECODER_PATH.arst_n) $rose(`COMM_ARB_DECODER_PATH.drw_inc_busy) |-> ##[0:DRW_BUSY_TIMEOUT] $fell(`COMM_ARB_DECODER_PATH.drw_inc_busy));
//
//	  // 5.- wb_slave_up_en must be set when uart write command is 'd18
//	  command_arbiter_decoder_wb_slave_up_en_correctly_set: assert property (@(posedge clk) disable iff(~`COMM_ARB_DECODER_PATH.arst_n) `COMM_ARB_DECODER_PATH.uart_mem_we && (`COMM_ARB_DECODER_PATH.uart_mem_waddr == 'd18) |=> $rose(`COMM_ARB_DECODER_PATH.wb_slave_up_en));
//
//	  // 6.- wb_slave_up_en can only be deasserted if no access transaction is ongoing from microprocessor to memory system
//	  command_arbiter_decoder_wb_slave_up_en_only_if_no_mem_sys_txn: assert property (@(posedge clk) disable iff(~`COMM_ARB_DECODER_PATH.arst_n) ~`COMM_ARB_DECODER_PATH.wb_slave_up_en |-> (~`DIG_TOP_PATH.wb_slave_rpg_busy) && (`DIG_TOP_PATH.wb_slave_rd_buff_empty) && (~`DIG_TOP_PATH.wb_slave_wpg_busy));
//
//	  // 7.- up_soft_reset can only be set if no access transaction is ongoing from microprocessor to memory system
//	  command_arbiter_decoder_up_soft_reset_only_if_no_mem_sys_txn: assert property (@(posedge clk) disable iff(~`COMM_ARB_DECODER_PATH.arst_n) `COMM_ARB_DECODER_PATH.up_soft_reset |-> (~`DIG_TOP_PATH.wb_slave_rpg_busy) && (`DIG_TOP_PATH.wb_slave_rd_buff_empty) && (~`DIG_TOP_PATH.wb_slave_wpg_busy));
//
//	`else
//	
//	`endif
//
//`endif
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////                                                                            mask_generator checkers and coverage model                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//`ifdef VERIFICATION
//
//	/* test plan
//	1.- when start is set, busy must change from 0 to 1
//	2.- start can't be set when busy or done are set
//	3.- when busy is not set, rpg_busy, wpg_busy must be zero, and rd_buff_empty must be high
//	4.- when rd_buff_empty is set, rd_buff_rden can't be set
//	5.- when wr_buff_full is set, wr_buff_wren can't be set
//	6.- rpg_busy, wpg_busy, rpg_ack, wpg_ack, wr_buff_full, rd_buff_rden, and wr_buff_wren can only be set when busy is set
//	*/
//
//	`ifdef SVA
//
//	  // 1.- when start is set, busy must change from 0 to 1
//	  mask_generator_busy_must_be_set_when_start: assert property (@(posedge clk) disable iff(~`DRW_PATH.arst_n) `DRW_PATH.start |=> $rose(`DRW_PATH.busy) );
//
//	  // 2.- start can't be set when busy or done are set
//	  mask_generator_no_start_if_busy_or_done: assert property (@(posedge clk) disable iff(~`DRW_PATH.arst_n) `DRW_PATH.start |-> ~(`DRW_PATH.busy || `DRW_PATH.done) );
//
//	  // 3.- when busy is not set, rpg_busy, wpg_busy must be zero, and rd_buff_empty must be high
//	  mask_generator_no_rpg_wpg_busy_no_rd_data_if_not_busy: assert property (@(posedge clk) disable iff(~`DRW_PATH.arst_n) ~`DRW_PATH.busy |-> (~`DRW_PATH.rpg_busy) && (~`DRW_PATH.wpg_busy) && `DRW_PATH.rd_buff_empty );
//
//	  // 4.- when rd_buff_empty is set, rd_buff_rden can't be set
//	  mask_generator_no_rd_when_empty: assert property (@(posedge clk) disable iff(~`DRW_PATH.arst_n) `DRW_PATH.rd_buff_empty |-> ~`DRW_PATH.rd_buff_rden );
//
//	  // 5.- when wr_buff_full is set, wr_buff_wren can't be set
//	  mask_generator_no_wr_when_full: assert property (@(posedge clk) disable iff(~`DRW_PATH.arst_n) `DRW_PATH.wr_buff_full |-> ~`DRW_PATH.wr_buff_wren );
//
//	  // 6.- rpg_busy, wpg_busy, rpg_ack, wpg_ack, wr_buff_full, rd_buff_rden, and wr_buff_wren can only be set when busy is set
//	  mask_generator_no_activity_when_not_busy: assert property (@(posedge clk) disable iff(~`DRW_PATH.arst_n) `DRW_PATH.rpg_busy || `DRW_PATH.wpg_busy || `DRW_PATH.rpg_ack || `DRW_PATH.wpg_ack || `DRW_PATH.wr_buff_full || `DRW_PATH.rd_buff_rden || `DRW_PATH.wr_buff_wren |-> `DRW_PATH.busy );
//
//	`else
//	
//	`endif
//
//`endif


endmodule
