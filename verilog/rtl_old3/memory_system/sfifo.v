///////////////////////////////////////////////////////////////////////////////////////
// Company: Mifral
// Engineer: Miguel Rivera
// 
// Design Name: memory_system
// Module Name: sfifo
//
// Description:
// implementation of a basic synchronous fifo buffer
///////////////////////////////////////////////////////////////////////////////////////

module sfifo #(parameter DATA_WIDTH = 32, parameter NUM_ELEMENTS = 64) (
	input wire clk,
	input wire arst_n,
	// Writing port //
	input wire wren,
	input wire [DATA_WIDTH-1:0] wdata,
	output wire pre_full,
	output reg full,
	// Reading port //
	input wire rden,
	output wire [DATA_WIDTH-1:0] rdata,
	output wire pre_empty,
	output reg empty
);

  localparam ADDR_WIDTH = $clog2(NUM_ELEMENTS);
  
  reg [DATA_WIDTH-1:0] mem [NUM_ELEMENTS];
  reg [ADDR_WIDTH-1:0] wrptr;
  reg [ADDR_WIDTH-1:0] rdptr;
  wire [ADDR_WIDTH-1:0] next_wrptr;
  wire [ADDR_WIDTH-1:0] next_rdptr;

  always@(posedge clk, negedge arst_n) begin
    if(~arst_n) begin
      empty <= 1'b1;
    end else begin
      if(wren && (~rden)) begin
        empty <= 1'b0;
      end else if(pre_empty) begin
        empty <= 1'b1;
      end
    end
  end
  
  always@(posedge clk, negedge arst_n) begin
    if(~arst_n) begin
      full <= 1'b0;
    end else begin
      if(rden && (~wren)) begin
        full <= 1'b0;
      end else if(pre_full) begin
        full <= 1'b1;
      end
    end
  end

  always@(posedge clk, negedge arst_n) begin
    if(~arst_n) begin
      wrptr <= {ADDR_WIDTH{1'b0}};
    end else begin
      if(wren && (~full)) begin
        wrptr <= next_wrptr;
      end
    end
  end
  
  always@(posedge clk, negedge arst_n) begin
    if(~arst_n) begin
      rdptr <= {ADDR_WIDTH{1'b0}};
    end else begin
      if(rden && (~empty)) begin
        rdptr <= next_rdptr;
      end
    end
  end
  
  always@(posedge clk) begin
    if(wren && (~full)) begin
      mem[wrptr] <= wdata;
    end
  end
  
  assign next_wrptr = wrptr + 1'b1;
  assign next_rdptr = rdptr + 1'b1;
  assign pre_empty = (next_rdptr == wrptr) && rden && (~wren);
  assign pre_full = (next_wrptr == rdptr) && wren && (~rden);
  assign rdata = mem[rdptr];

endmodule
