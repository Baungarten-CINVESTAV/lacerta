module wb_master_bfm #(
  parameter DATA_WIDTH = 32, // Data width in bits
  parameter ADDR_WIDTH = 32  // Address width in bits
)(
  input logic                       wb_clk_i, // System clock
  input logic                       wb_rst_i // Synchronous reset (active high)
);
  // Wishbone interface
  logic [ADDR_WIDTH-1:0]     wb_adr_o; // Address input
  logic [DATA_WIDTH-1:0]     wb_dat_i; // Data input
  logic [DATA_WIDTH-1:0]     wb_dat_o; // Data output
  logic                      wb_we_o;  // Write enable
  logic [(DATA_WIDTH/8)-1:0] wb_sel_o; // Byte select
  logic                      wb_stb_o; // Strobe
  logic                      wb_cyc_o; // Cycle valid
  logic                      wb_ack_i;  // Acknowledge

  task wb_master_initialize();
    wb_adr_o <= {ADDR_WIDTH{1'b0}};
    wb_dat_o <= {ADDR_WIDTH{1'b0}};
    wb_sel_o <= {(DATA_WIDTH/8){1'b0}};
    wb_we_o <= 1'b0;
    wb_stb_o <= 1'b0;
    wb_cyc_o <= 1'b0;
  endtask

  task wb_master_wr_data(input logic [DATA_WIDTH-1:0] wdata, input logic [ADDR_WIDTH-1:0] waddr, input logic [(DATA_WIDTH/8)-1:0] wmask = '1);
    @(posedge wb_clk_i);
    wb_adr_o <= waddr;
    wb_dat_o <= wdata;
    wb_we_o <= 1'b1;
    wb_sel_o <= wmask;
    wb_stb_o <= 1'b1;
    wb_cyc_o <= 1'b1;
    while(wb_ack_i == 1'b0) begin
      @(posedge wb_clk_i);
    end
    wb_adr_o <= {ADDR_WIDTH{1'b0}};
    wb_dat_o <= {ADDR_WIDTH{1'b0}};
    wb_sel_o <= {(DATA_WIDTH/8){1'b0}};
    wb_we_o <= 1'b0;
    wb_stb_o <= 1'b0;
    wb_cyc_o <= 1'b0;
  endtask

  task wb_master_rd_data(input logic [ADDR_WIDTH-1:0] raddr, output logic [DATA_WIDTH-1:0] rdata);
    @(posedge wb_clk_i);
    wb_adr_o <= raddr;
    wb_we_o <= 1'b0;
    wb_stb_o <= 1'b1;
    wb_cyc_o <= 1'b1;
    while(wb_ack_i == 1'b0) begin
      @(posedge wb_clk_i);
    end
    wb_adr_o <= {ADDR_WIDTH{1'b0}};
    wb_stb_o <= 1'b0;
    wb_cyc_o <= 1'b0;
    rdata = wb_dat_i;
  endtask

endmodule
