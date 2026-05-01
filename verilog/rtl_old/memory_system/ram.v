module ram(
  input wire clk,
  // Reading port //
  input wire main_mem_rden,
  input wire [MAIN_MEM_ADDR_WIDTH - 1 : 0] main_mem_rd_addr,
  output reg [MAIN_MEM_DATA_WIDTH - 1 : 0] main_mem_rd_data,
  output reg main_mem_rd_data_valid,
  
  // Writing port //
  input wire main_mem_wren,
  output wire main_mem_wr_data_ack,
  input wire [MAIN_MEM_ADDR_WIDTH - 1 : 0] main_mem_wr_addr,
  input wire [MAIN_MEM_DATA_WIDTH - 1 : 0] main_mem_wr_data
);

//  logic [MAIN_MEM_DATA_WIDTH - 1 : 0] mem [0 : (2**MAIN_MEM_ADDR_WIDTH) - 1];
  reg [MAIN_MEM_DATA_WIDTH - 1 : 0] mem [0 : 640*480 + 100000];
//	initial begin
//		$readmemh("C:/Users/mrive/OneDrive/Documentos/lacerta/rtl/soc/picorv32/instructions_8bits.hex", mem);
//	end

  assign main_mem_wr_data_ack = main_mem_wren;

  always@(posedge clk) begin
    if(main_mem_wren)
      mem[main_mem_wr_addr] <= main_mem_wr_data;
    main_mem_rd_data <= mem[main_mem_rd_addr];
    main_mem_rd_data_valid <= main_mem_rden && !main_mem_rd_data_valid;
  end
    //assign main_mem_rd_data = mem[main_mem_rd_addr];
    //assign main_mem_rd_data_valid = main_mem_rden;

//  initial begin $readmemb("../python/image.bin", mem); end

endmodule


