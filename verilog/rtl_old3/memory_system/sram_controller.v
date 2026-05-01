///////////////////////////////////////////////////////////////////////////////////////
// Company: Mifral
// Engineer: Miguel Rivera
// 
// Design Name: memory_system
// Module Name: sram_controller
//
// Description:
// implementation of a basic controller for a volatile sram, we write and read
// combinationally, but we send the read data synced to clk
///////////////////////////////////////////////////////////////////////////////////////

module sram_controller #(parameter MAIN_MEM_ADDR_WIDTH = 19, parameter MAIN_MEM_DATA_WIDTH = 8) (
    input wire clk,
    input wire arst_n,

    // Reading port
    input wire main_mem_rden,
    input wire [MAIN_MEM_ADDR_WIDTH-1:0] main_mem_rd_addr,
    output reg [MAIN_MEM_DATA_WIDTH-1:0] main_mem_rd_data,
    output reg main_mem_rd_data_valid,
    
    // Writing port
    input wire main_mem_wren,
    output wire main_mem_wr_data_ack,
    input wire [MAIN_MEM_ADDR_WIDTH-1:0] main_mem_wr_addr,
    input wire [MAIN_MEM_DATA_WIDTH-1:0] main_mem_wr_data,

    // SRAM interface
    output wire [MAIN_MEM_ADDR_WIDTH-1:0] sram_addr,
    input wire [MAIN_MEM_DATA_WIDTH-1:0] sram_data_in,
    output wire [MAIN_MEM_DATA_WIDTH-1:0] sram_data_out,
    output wire [MAIN_MEM_DATA_WIDTH-1:0] sram_data_oeb, // if 0 sram_data is output, if 1 sram_data is input
    output wire sram_ce_n,
    output wire sram_oe_n,
    output wire sram_we_n
);

// we control the sram combinationally
assign sram_addr = (main_mem_rden || main_mem_rd_data_valid) ? main_mem_rd_addr : main_mem_wr_addr; // read operation has priority
assign sram_ce_n = 1'b0; // we tie the chip enable to zero, this will be done at pcb level
assign sram_oe_n = (main_mem_rden || main_mem_rd_data_valid) ? 1'b0 : 1'b1; // output enabled is set when we are not reading, as read operation has priority
assign sram_we_n = (main_mem_rden || main_mem_rd_data_valid) ? 1'b1 : ~main_mem_wren; // if reading, we deactive, otherwise, we active we_n if write operation is requested
assign sram_data_out = main_mem_wr_data; // high impedance if reading, otherwise, we send writing data
assign main_mem_wr_data_ack = main_mem_wren && (!main_mem_rden); // we acknowledge write operation only when no read is ongoing, and a write access is requested
assign sram_data_oeb = (main_mem_rden || main_mem_rd_data_valid) ? 1'b1 : 1'b0; // if 0 sram_data is output, if 1 sram data is input, if reading, we need sram_data to be an input, otherwise an output

// we send data and acknowledge signals back to lacerta synchronized to clk
always @(posedge clk, negedge arst_n) begin
  if(!arst_n) begin
    main_mem_rd_data <= {MAIN_MEM_DATA_WIDTH{1'b0}};
    main_mem_rd_data_valid <= 1'b0;
  end else begin
    main_mem_rd_data_valid <= 1'b0; // single cycle
    if(main_mem_rden && (!main_mem_rd_data_valid)) begin
      main_mem_rd_data <= sram_data_in;
      main_mem_rd_data_valid <= 1'b1;
    end
  end
end

endmodule
