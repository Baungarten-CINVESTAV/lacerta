module lacerta_soc_fpga (
  input wire clk,
  input wire arst_n,

  input wire [17:0] sw,
  output wire [17:0] ledr,
  output wire [7:0] ledg,
  // Debug
  output [6:0] HEX0,
  output [6:0] HEX1,
  output [6:0] HEX2,
  output [6:0] HEX3,
  output [6:0] HEX4,
  output [6:0] HEX5,
  output [6:0] HEX6,
  output [6:0] HEX7,

	// UART interface
	input wire rx,
	output wire tx,

  // SRAM interface
  output wire [MAIN_MEM_ADDR_WIDTH-1:0] sram_addr,
  inout wire [MAIN_MEM_DATA_WIDTH-1:0] sram_data,
  output wire sram_ce_n,
  output wire sram_oe_n,
  output wire sram_we_n,
  output wire sram_lb_n,

  // SPI ports
  output wire sck,
  output wire ss,
  output wire mosi,
  // data/command send to tft screen
  output wire dc,
  output wire res,
  output wire blk
);

	// Wishbone interface - this is connected to picorv32 master, naming is from master perspectiv, naming is from master perspectivee
	wire [WB_ADDR_WIDTH-1:0]		 wb_adr_o; // Address input
	wire [WB_DATA_WIDTH-1:0]		 wb_dat_i; // Data input
	wire [WB_DATA_WIDTH-1:0]		 wb_dat_o; // Data output
	wire 												 wb_we_o;  // Write enable
	wire [(WB_DATA_WIDTH/8)-1:0] wb_sel_o; // Byte select
	wire 												 wb_stb_o; // Strobe
	wire 												 wb_cyc_o; // Cycle valid
	wire 												 wb_ack_i;  // Acknowledge
	wire                         mem_instr;
  wire                         up_soft_reset;
  wire [MAIN_MEM_DATA_WIDTH-1:0] sram_data_in; // gpio
  wire [MAIN_MEM_DATA_WIDTH-1:0] sram_data_out; // gpio
  wire [MAIN_MEM_DATA_WIDTH-1:0] sram_data_oeb; // if 0 sram_data is output, if 1 sram_data is unput
  
  assign sram_data = sram_data_oeb ? 8'dz : sram_data_out;
  assign sram_data_in = sram_data_oeb ? sram_data : 8'd0;
  
	// lacerta digital top instantiation
	dig_top_fpga dig_top_i(
	  .clk(clk),
	  .arst_n(arst_n),

  .sw(sw),
  .ledr(ledr),
  .ledg(ledg),
  // Debug
  .HEX0(HEX0),
  .HEX1(HEX1),
  .HEX2(HEX2),
  .HEX3(HEX3),
  .HEX4(HEX4),
  .HEX5(HEX5),
  .HEX6(HEX6),
  .HEX7(HEX7),

    // uprocessor interface
    .up_soft_reset(up_soft_reset),
	  
		// UART interface
		.rx(rx),
		.tx(tx),
	
	  // Wishbone interface
	  .wb_adr_i(wb_adr_o), // Address input
	  .wb_dat_i(wb_dat_o), // Data input
	  .wb_dat_o(wb_dat_i), // Data output
	  .wb_we_i(wb_we_o),  // Write enable
	  .wb_sel_i(wb_sel_o), // Byte select
	  .wb_stb_i(wb_stb_o), // Strobe
	  .wb_cyc_i(wb_cyc_o), // Cycle valid
	  .wb_ack_o(wb_ack_i),  // Acknowledge


  // SRAM interface
  .sram_addr(sram_addr),
  .sram_data_in(sram_data_in),
  .sram_data_out(sram_data_out),
  .sram_data_oeb(sram_data_oeb),
  .sram_ce_n(sram_ce_n),
  .sram_oe_n(sram_oe_n),
  .sram_we_n(sram_we_n),
  .sram_lb_n(sram_lb_n),

  // SPI ports
  .sck(sck),
  .ss(ss),
  .mosi(mosi),
  // data/command send to tft screen
  .dc(dc),
  .res(res),
  .blk(blk)
	);

/***************************************************************
 * picorv32_wb
 ***************************************************************/
 
picorv32_wb #(
.ENABLE_COUNTERS        (1),
.ENABLE_COUNTERS64      (1),
.ENABLE_REGS_16_31      (1),
.ENABLE_REGS_DUALPORT   (1),
.TWO_STAGE_SHIFT        (1),
.BARREL_SHIFTER         (0),
.TWO_CYCLE_COMPARE      (0),
.TWO_CYCLE_ALU          (0),
.COMPRESSED_ISA         (0),
.CATCH_MISALIGN         (1),
.CATCH_ILLINSN          (1),
.ENABLE_PCPI            (0),
.ENABLE_MUL             (0),
.ENABLE_FAST_MUL        (0),
.ENABLE_DIV             (0),
.ENABLE_IRQ             (0),
.ENABLE_IRQ_QREGS       (1),
.ENABLE_IRQ_TIMER       (1),
.ENABLE_TRACE           (0),
.REGS_INIT_ZERO         (0),
.MASKED_IRQ             (32'h0000_0000),
.LATCHED_IRQ            (32'hffff_ffff),
.PROGADDR_RESET         (UP_INSTR_BASE_ADDRESS),
.PROGADDR_IRQ           (32'h0000_0010),
.STACKADDR              (32'hffff_ffff)
) picorv32_wb_i (
//	output trap,

	// Wishbone interfaces
	.wb_rst_i((!arst_n) || up_soft_reset),
	.wb_clk_i(clk),

	.wbm_adr_o(wb_adr_o),
	.wbm_dat_o(wb_dat_o),
	.wbm_dat_i(wb_dat_i),
	.wbm_cyc_o(wb_cyc_o),
	.wbm_stb_o(wb_stb_o),
	.wbm_we_o(wb_we_o),
	.wbm_sel_o(wb_sel_o),
	.wbm_ack_i(wb_ack_i),

	// Pico Co-Processor Interface (PCPI)
//	output        .pcpi_valid,
//	output [31:0] .pcpi_insn,
//	output [31:0] .pcpi_rs1,
//	output [31:0] .pcpi_rs2,
	.pcpi_wr(1'b0),
	.pcpi_rd(32'd0),
	.pcpi_wait(1'b0),
	.pcpi_ready(1'b0),

	// IRQ interface
	.irq(32'd0),
//	output [31:0] eoi,

//`ifdef RISCV_FORMAL
//	output        rvfi_valid,
//	output [63:0] rvfi_order,
//	output [31:0] rvfi_insn,
//	output        rvfi_trap,
//	output        rvfi_halt,
//	output        rvfi_intr,
//	output [ 4:0] rvfi_rs1_addr,
//	output [ 4:0] rvfi_rs2_addr,
//	output [31:0] rvfi_rs1_rdata,
//	output [31:0] rvfi_rs2_rdata,
//	output [ 4:0] rvfi_rd_addr,
//	output [31:0] rvfi_rd_wdata,
//	output [31:0] rvfi_pc_rdata,
//	output [31:0] rvfi_pc_wdata,
//	output [31:0] rvfi_mem_addr,
//	output [ 3:0] rvfi_mem_rmask,
//	output [ 3:0] rvfi_mem_wmask,
//	output [31:0] rvfi_mem_rdata,
//	output [31:0] rvfi_mem_wdata,
//`endif
//
//	// Trace Interface
//	output        trace_valid,
//	output [35:0] trace_data,

	.mem_instr(mem_instr)
);

endmodule
