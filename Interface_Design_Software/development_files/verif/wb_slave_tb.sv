module wb_slave_tb;
  localparam DATA_WIDTH = 32;
  localparam ADDR_WIDTH = 32;

  bit clk;
  bit arst_n;
  always #5ns clk = !clk;
  assign #20ns arst_n = 1'b1;

	logic [DATA_WIDTH-1:0] tb_rdata;
  wb_master_bfm #(DATA_WIDTH, ADDR_WIDTH) wb_master_if (clk, !arst_n);

  // Memory related signals
  logic mem_we;
  logic [DATA_WIDTH-1:0] mem_wdata;
  logic [(DATA_WIDTH/8)-1:0] mem_wmask;
  logic [ADDR_WIDTH-1:0] mem_waddr;
  logic mem_wr_data_ack;
  logic mem_re;
  logic [ADDR_WIDTH-1:0] mem_raddr;
  logic [DATA_WIDTH-1:0] mem_rdata;
  logic mem_rdy;

  wb_slave_memory_mapped #(DATA_WIDTH, ADDR_WIDTH) wb_slave_i (
    .wb_clk_i(clk), // System clock
    .wb_rst_i(!arst_n), // Synchronous reset (active high)
    // Memory related signals
    .mem_we(mem_we),
    .mem_wdata(mem_wdata),
    .mem_wmask(mem_wmask),
    .mem_waddr(mem_waddr),
		.mem_wr_data_ack(mem_wr_data_ack),
    .mem_re(mem_re),
    .mem_raddr(mem_raddr),
    .mem_rdata(mem_rdata),
    .mem_rdy(mem_rdy),
    // Wishbone interface
    .wb_adr_i(wb_master_if.wb_adr_o), // Address input
    .wb_dat_i(wb_master_if.wb_dat_o), // Data input
    .wb_dat_o(wb_master_if.wb_dat_i), // Data output
    .wb_we_i(wb_master_if.wb_we_o),  // Write enable
    .wb_sel_i(wb_master_if.wb_sel_o), // Byte select
    .wb_stb_i(wb_master_if.wb_stb_o), // Strobe
    .wb_cyc_i(wb_master_if.wb_cyc_o), // Cycle valid
    .wb_ack_o(wb_master_if.wb_ack_i)  // Acknowledge
  );

  ram ram_i(
    .clk(clk),
    .arst_n(arst_n),
    // Reading port //
    .main_mem_rden(mem_re),
    .main_mem_rd_addr(mem_raddr),
    .main_mem_rd_data(mem_rdata),
    .main_mem_rd_data_valid(mem_rdy),
    
    // Writing port //
    .main_mem_wren(mem_we),
    .main_mem_wr_addr(mem_waddr),
    .main_mem_wr_data(mem_wdata),
    .main_mem_wr_data_ack(mem_wr_data_ack)
  );

	initial begin
		wb_master_if.wb_master_initialize();
		repeat(10) @(posedge clk);
		wb_master_if.wb_master_wr_data(32'hDEAD_BEEF, 32'h00000000);
		//repeat(1) @(posedge clk);
		wb_master_if.wb_master_rd_data(32'h00000000, tb_rdata);
		$display("=============== %X", tb_rdata);
//		#1us;
		repeat(10) @(posedge clk);
		$finish;
	end

endmodule
