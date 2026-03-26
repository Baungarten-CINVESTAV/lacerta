module lacerta_tb;

	bit clk, arst_n;
	always #5ns clk = !clk;
	assign #20ns arst_n = 1'b1;

	logic [WB_DATA_WIDTH-1:0] tb_rdata;
	wb_master_bfm #(WB_DATA_WIDTH, WB_ADDR_WIDTH) wb_master_if (clk, !arst_n);

  // VGA signals
  logic [7:0] vga_ored;
  logic [7:0] vga_ogreen;
  logic [7:0] vga_oblue;
  logic vga_hsync;
  logic vga_vsync;
  logic vga_sync;
  logic vga_blank;
  logic vga_clk;

	initial begin
		wb_master_if.wb_master_initialize();
		repeat(10) @(posedge clk);
		wb_master_if.wb_master_wr_data(32'd0, 32'd0); // set host_wpg_st_addr to 0
		wb_master_if.wb_master_wr_data(32'd10, 32'd1); // set host_wpg_burst_length to 10
		wb_master_if.wb_master_wr_data(32'd0, 32'd2); // set host_wpg_busy to 1
		repeat(10) begin
			wb_master_if.wb_master_wr_data($random, 32'd6); // write random data through host writing buffer (0)
		end

		//wb_master_if.wb_master_wr_data(32'd0, 32'd3); // set host_rpg_st_addr to 0
		//wb_master_if.wb_master_wr_data(32'd10, 32'd4); // set host_rpg_burst_length to 10

		//wb_master_if.wb_master_wr_data(32'hDEAD_BEEF, 32'h00000000);
		//repeat(1) @(posedge clk);
		//wb_master_if.wb_master_rd_data(32'h00000000, tb_rdata);
		$display("=============== %X", tb_rdata);
		repeat(100) @(posedge clk);
		$finish;
	end

	initial begin // timeout thread
		#10ms;
		$finish;
	end


	dig_top dig_top_i(
	  .clk(clk),
	  .arst_n(arst_n),
	
	  // Wishbone interface
	  .wb_adr_i(wb_master_if.wb_adr_o), // Address input
	  .wb_dat_i(wb_master_if.wb_dat_o), // Data input
	  .wb_dat_o(wb_master_if.wb_dat_i), // Data output
	  .wb_we_i(wb_master_if.wb_we_o),  // Write enable
	  .wb_sel_i(wb_master_if.wb_sel_o), // Byte select
	  .wb_stb_i(wb_master_if.wb_stb_o), // Strobe
	  .wb_cyc_i(wb_master_if.wb_cyc_o), // Cycle valid
	  .wb_ack_o(wb_master_if.wb_ack_i),  // Acknowledge
	  
	  // VGA signals
	  .vga_ored(vga_ored),
	  .vga_ogreen(vga_ogreen),
	  .vga_oblue(vga_oblue),
	  .vga_hsync(vga_hsync),
	  .vga_vsync(vga_vsync),
	  .vga_sync(vga_sync),
	  .vga_blank(vga_blank),
	  .vga_clk(vga_clk)
	);

endmodule
