//////////////////////////////////////////////////////////////////////////////////
// Company: Mifral
// Engineer: Miguel Rivera
// 
// Design Name: wb_slave_memory_mapped
// Module Name: wb_slave_memory_mapped
//
// Description: 
// This module implements a wishbone memory-mapped slave interface, it allows a 
// wishbone master to perform read and write transactions to an external memory
//////////////////////////////////////////////////////////////////////////////////

module wb_slave_memory_mapped #(
  parameter DATA_WIDTH = 32, // Data width in bits
  parameter ADDR_WIDTH = 32  // Address width in bits
)(
  input wire wb_clk_i, // System clock
  input wire wb_rst_i, // Synchronous reset (active high)
  input wire up_soft_reset,

  // Memory related signals
  output reg mem_we,
  output reg [DATA_WIDTH-1:0] mem_wdata,
  output reg [(DATA_WIDTH/8)-1:0] mem_wmask,
  output reg [ADDR_WIDTH-1:0] mem_waddr,
  input wire mem_wr_data_ack,
  output reg mem_re,
  output reg [ADDR_WIDTH-1:0] mem_raddr,
  input wire [DATA_WIDTH-1:0] mem_rdata,
  input wire mem_rdy,

  // Wishbone interface
  input wire [ADDR_WIDTH-1:0] wb_adr_i, // Address input
  input wire [DATA_WIDTH-1:0] wb_dat_i, // Data input
  output reg [DATA_WIDTH-1:0] wb_dat_o, // Data output
  input wire wb_we_i,  // Write enable
  input wire [(DATA_WIDTH/8)-1:0] wb_sel_i, // Byte select
  input wire wb_stb_i, // Strobe
  input wire wb_cyc_i, // Cycle valid
  output reg wb_ack_o  // Acknowledge
);

  reg rd_pending;
  reg wr_pending;

  // Wishbone transaction handling
  always @(posedge wb_clk_i) begin // reset is synchronous
    if(wb_rst_i || up_soft_reset) begin
      mem_we <= 1'b0;
      mem_wdata <= {DATA_WIDTH{1'b0}};
      mem_wmask <= {DATA_WIDTH/8{1'b0}};
      mem_waddr <= {ADDR_WIDTH{1'b0}};
      wr_pending <= 1'b0;
      mem_re <= 1'b0;
      mem_raddr <= {ADDR_WIDTH{1'b0}};
      rd_pending <= 1'b0;
      wb_dat_o <= {DATA_WIDTH{1'b0}};
      wb_ack_o <= 1'b0;
    end else begin
      wb_ack_o <= 1'b0; // Default: no acknowledge
      mem_re <= 1'b0;
      mem_we <= 1'b0;

      if(wb_cyc_i && wb_stb_i && !wb_ack_o) begin // new transaction
        if(wb_we_i) begin // Write operation
          mem_we <= !wr_pending;
          mem_wdata <= wb_dat_i;
          mem_wmask <= wb_sel_i;
          mem_waddr <= wb_adr_i;
          wr_pending <= 1'b1;
          if(mem_wr_data_ack) begin
            wr_pending <= 1'b0;
            wb_ack_o <= 1'b1; // Acknowledge this cycle
          end
        end else begin
          // Read operation
          mem_re <= !rd_pending;
          mem_raddr <= wb_adr_i;
          rd_pending <= 1'b1;
          if(mem_rdy) begin
            rd_pending <= 1'b0;
            wb_ack_o <= 1'b1; // Acknowledge this cycle
            wb_dat_o <= mem_rdata;
          end
        end
      end
    end
  end

endmodule
