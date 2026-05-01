module mem_sys (
  input wire mem_sys_clk,
  input wire arst_n,

  // Main memory signals
  // Reading port //
  output wire main_mem_rden,
  output wire [MAIN_MEM_ADDR_WIDTH - 1 : 0] main_mem_rd_addr,
  input wire [MAIN_MEM_DATA_WIDTH - 1 : 0] main_mem_rd_data,
  input wire main_mem_rd_data_valid,
  
  // Writing port //
  output wire main_mem_wren,
  output wire [MAIN_MEM_ADDR_WIDTH - 1 : 0] main_mem_wr_addr,
  output wire [MAIN_MEM_DATA_WIDTH - 1 : 0] main_mem_wr_data,
  input wire main_mem_wr_data_ack,

  // accumulation raw dependencies
  input wire [NUM_READ_BUFFERS - 1 : 0] rpg_pre_stall,
  input wire [NUM_READ_BUFFERS - 1 : 0] rpg_stall,

  // write pattern generator signals
  input wire [MAIN_MEM_ADDR_WIDTH*NUM_WRITE_BUFFERS - 1 : 0] wpg_st_addr,
  input wire [MAIN_MEM_ADDR_WIDTH*NUM_WRITE_BUFFERS - 1 : 0] wpg_burst_length,
  input wire [NUM_WRITE_BUFFERS - 1 : 0] wpg_busy,
  output wire [NUM_WRITE_BUFFERS - 1 : 0] wpg_ack,

  // read pattern generator signals
  input wire [MAIN_MEM_ADDR_WIDTH*NUM_READ_BUFFERS - 1 : 0] rpg_st_addr,
  input wire [MAIN_MEM_ADDR_WIDTH*NUM_READ_BUFFERS - 1 : 0] rpg_burst_length,
  input wire [NUM_READ_BUFFERS - 1 : 0] rpg_busy,
  output wire [NUM_READ_BUFFERS - 1 : 0] rpg_ack,
  output wire [NUM_READ_BUFFERS - 1 : 0] rpg_burst_ongoing,

  // Writing port for writing buffers //
  input wire [NUM_WRITE_BUFFERS - 1 : 0] wr_buff_wren,
  input wire [MAIN_MEM_DATA_WIDTH*NUM_WRITE_BUFFERS - 1 : 0] wr_buff_wdata,
  output wire [NUM_WRITE_BUFFERS - 1 : 0] wr_buff_full,
  output wire [NUM_WRITE_BUFFERS - 1 : 0] wr_buff_empty,

  // Reading port for reading buffers //
  input wire [NUM_READ_BUFFERS - 1 : 0] rd_buff_rden,
  output wire [MAIN_MEM_DATA_WIDTH*NUM_READ_BUFFERS - 1 : 0] rd_buff_rdata,
  output wire [NUM_READ_BUFFERS - 1 : 0] rd_buff_empty
);

  wire [NUM_WRITE_BUFFERS - 1 : 0] wr_buff_rden;
  wire [MAIN_MEM_DATA_WIDTH*NUM_WRITE_BUFFERS - 1 : 0] wr_buff_rdata;
  wire [NUM_READ_BUFFERS - 1 : 0] rd_buff_wren;
  wire [MAIN_MEM_DATA_WIDTH*NUM_READ_BUFFERS - 1 : 0] rd_buff_wdata;
  wire [NUM_READ_BUFFERS - 1 : 0] rd_buff_full;
  wire [NUM_READ_BUFFERS - 1 : 0] rd_buff_half_empty;

// Buffers filler instantiation
  buffers_filler buffers_filler_i (
    .mem_sys_clk(mem_sys_clk),
    .arst_n(arst_n),

    // Read pattern generator //
    .rpg_st_addr(rpg_st_addr),
    .rpg_burst_length(rpg_burst_length),
    .rpg_busy(rpg_busy),
    .rpg_ack(rpg_ack),
    .rpg_burst_ongoing(rpg_burst_ongoing),
    .rpg_stall(rpg_stall),
    .rpg_pre_stall(rpg_pre_stall),

    // Main memory side //
    .main_mem_rden(main_mem_rden),
    .main_mem_rd_addr(main_mem_rd_addr),
    .main_mem_rd_data(main_mem_rd_data),
    .main_mem_rd_data_valid(main_mem_rd_data_valid),
    
    // Writing port for reading buffers //
    .rd_buff_wren(rd_buff_wren),
    .rd_buff_wdata(rd_buff_wdata),
		.rd_buff_half_empty(rd_buff_half_empty),
    .rd_buff_full(rd_buff_full)
  );

// Buffers discharger instantiation
  buffers_discharger buffers_discharger_i (
    .mem_sys_clk(mem_sys_clk),
    .arst_n(arst_n),
  
    // Write pattern generator //
    .wpg_st_addr(wpg_st_addr),
    .wpg_burst_length(wpg_burst_length),
    .wpg_busy(wpg_busy),
    .wpg_ack(wpg_ack),

    // Main memory side //
    .main_mem_wren(main_mem_wren),
    .main_mem_wr_addr(main_mem_wr_addr),
    .main_mem_wr_data(main_mem_wr_data),
    .main_mem_wr_data_ack(main_mem_wr_data_ack),
    
    // Reading port for writing buffers //
    .wr_buff_rden(wr_buff_rden),
    .wr_buff_rdata(wr_buff_rdata),
    .wr_buff_empty(wr_buff_empty)
  );

// Buffers instantiation
  buffers buffers_i (
    .mem_sys_clk(mem_sys_clk),
    .arst_n(arst_n),
    
    // Writing port for writing buffers //
    .wr_buff_wren(wr_buff_wren),
    .wr_buff_wdata(wr_buff_wdata),
    .wr_buff_full(wr_buff_full),

    // Reading port for writing buffers //
    .wr_buff_rden(wr_buff_rden),
    .wr_buff_rdata(wr_buff_rdata),
    .wr_buff_empty(wr_buff_empty),
    
    // Writing port for reading buffers //
    .rd_buff_wren(rd_buff_wren),
    .rd_buff_wdata(rd_buff_wdata),
    .rd_buff_full(rd_buff_full),

    // Reading port for reading buffers //
    .rd_buff_rden(rd_buff_rden),
    .rd_buff_rdata(rd_buff_rdata),
		.rd_buff_half_empty(rd_buff_half_empty),
    .rd_buff_empty(rd_buff_empty)
  );

endmodule
