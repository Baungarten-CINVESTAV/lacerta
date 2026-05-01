///////////////////////////////////////////////////////////////////////////////////////
// Company: Mifral
// Engineer: Miguel Rivera
// 
// Design Name: memory_system
// Module Name: buffers
//
// Description:
// this module instantiates and wraps all the reading and writing buffers,
// that are used by all consumers and producers of data, these buffers are filled, 
// discharged by buffers_filler, and buffer_discharger arbiters respectively
///////////////////////////////////////////////////////////////////////////////////////

module buffers (
  input wire mem_sys_clk,
  input wire arst_n,
  
  // Writing port for writing buffers //
  input wire [NUM_WRITE_BUFFERS - 1 : 0] wr_buff_wren,
  input wire [MAIN_MEM_DATA_WIDTH*NUM_WRITE_BUFFERS - 1 : 0] wr_buff_wdata,
  output wire [NUM_WRITE_BUFFERS - 1 : 0] wr_buff_full,
  
  // Reading port for writing buffers //
  input wire [NUM_WRITE_BUFFERS - 1 : 0] wr_buff_rden,
  output wire [MAIN_MEM_DATA_WIDTH*NUM_WRITE_BUFFERS - 1 : 0] wr_buff_rdata,
  output wire [NUM_WRITE_BUFFERS - 1 : 0] wr_buff_pre_empty,
  output wire [NUM_WRITE_BUFFERS - 1 : 0] wr_buff_empty,
  
  // Writing port for reading buffers //
  input wire [NUM_READ_BUFFERS - 1 : 0] rd_buff_wren,
  input wire [MAIN_MEM_DATA_WIDTH*NUM_READ_BUFFERS - 1 : 0] rd_buff_wdata,
  output wire [NUM_READ_BUFFERS - 1 : 0] rd_buff_pre_full,
  output wire [NUM_READ_BUFFERS - 1 : 0] rd_buff_full,
  
  // Reading port for reading buffers //
  input wire [NUM_READ_BUFFERS - 1 : 0] rd_buff_rden,
  output wire [MAIN_MEM_DATA_WIDTH*NUM_READ_BUFFERS - 1 : 0] rd_buff_rdata,
  output wire [NUM_READ_BUFFERS - 1 : 0] rd_buff_empty
);

genvar i;

  generate

    for(i = 0; i < NUM_WRITE_BUFFERS; i = i + 1) begin: WRITE_BUFFER // Instantiate writing buffers

      sfifo #(MAIN_MEM_DATA_WIDTH, NUM_ELEMENTS_WRITE_BUFFERS) wr_buffer (
				// Writing port (write clock domain)
				.clk(mem_sys_clk),
				.arst_n(arst_n),
				.wren(wr_buff_wren[i]),
				.wdata(wr_buff_wdata[i*MAIN_MEM_DATA_WIDTH +: MAIN_MEM_DATA_WIDTH]),
				.full(wr_buff_full[i]),
				// Reading port (read clock domain)
				.rden(wr_buff_rden[i]),
				.rdata(wr_buff_rdata[i*MAIN_MEM_DATA_WIDTH +: MAIN_MEM_DATA_WIDTH]),
				.pre_empty(wr_buff_pre_empty[i]),
				.empty(wr_buff_empty[i])
      );

    end

    for( i = 0; i < NUM_READ_BUFFERS; i = i + 1) begin: READ_BUFFER // Instantiate reading buffers

      sfifo #(MAIN_MEM_DATA_WIDTH, NUM_ELEMENTS_READ_BUFFERS) rd_buffer (
				// Writing port (write clock domain)
				.clk(mem_sys_clk),
				.arst_n(arst_n),
				.wren(rd_buff_wren[i]),
				.wdata(rd_buff_wdata[i*MAIN_MEM_DATA_WIDTH +: MAIN_MEM_DATA_WIDTH]),
        .pre_full(rd_buff_pre_full[i]),
				.full(rd_buff_full[i]),
				// Reading port (read clock domain)
				.rden(rd_buff_rden[i]),
				.rdata(rd_buff_rdata[i*MAIN_MEM_DATA_WIDTH +: MAIN_MEM_DATA_WIDTH]),
				.empty(rd_buff_empty[i])
      );

    end

  endgenerate

endmodule
