//////////////////////////////////////////////////////////////////////////////////
// Company: Mifral
// Engineer: Miguel Rivera
// 
// Design Name: wb_slave_to_mem_sys_ports
// Module Name: wb_slave_to_mem_sys_ports
//
// Description: 
// This module implements a wishbone memory-mapped slave interface, it allows a 
// wishbone master to perform read and write transactions to an external memory
//////////////////////////////////////////////////////////////////////////////////

module wb_slave_to_mem_sys_ports #(
  parameter DATA_WIDTH = 32, 		// Data width in bits
  parameter ADDR_WIDTH = 32, 		// Address width in bits
  parameter MEM_DATA_WIDTH = 8 	// Memory system data width, to know how many accessses to acknowledge a wishbone transaction
)(
  input wire wb_clk_i, // System clock
  input wire wb_rst_i, // Synchronous reset (active high)

  input wire up_en, // set when microprocessor is enabled
  input wire up_soft_reset, // set when microprocessor had a soft reset
  
  // Wishbone interface
  input wire [ADDR_WIDTH-1:0] wb_adr_i, // Address input
  input wire [DATA_WIDTH-1:0] wb_dat_i, // Data input
  output reg [DATA_WIDTH-1:0] wb_dat_o, // Data output
  input wire wb_we_i, // Write enable
  input wire [(DATA_WIDTH/8)-1:0] wb_sel_i, // Byte select , as main memory data width is 8, we do not require this, thus, unused for this module
  input wire wb_stb_i, // Strobe
  input wire wb_cyc_i, // Cycle valid
  output reg wb_ack_o, // Acknowledge
  
  // read pattern generator related signals
  output reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] rpg_st_addr,
  output reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] rpg_burst_length,
  output reg rpg_busy,
  input wire rpg_ack,
  // reading buffer related signals
  output reg rd_buff_rden,
  input wire [MEM_DATA_WIDTH - 1 : 0] rd_buff_rdata,
  input wire rd_buff_empty,
  
  // write pattern generator signals
  output reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] wpg_st_addr,
  output reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] wpg_burst_length,
  output reg wpg_busy,
  input wire wpg_ack,
  // Writing port for writing buffers //
  output reg wr_buff_wren,
  output reg [MEM_DATA_WIDTH - 1 : 0] wr_buff_wdata,
  input wire wr_buff_full
);

localparam NUM_ACCESSES = DATA_WIDTH / MEM_DATA_WIDTH; // DATA_WIDTH must be always divisible by MEM_DATA_WIDTH
localparam COUNT_WIDTH = NUM_ACCESSES < 2 ? 1 : $clog2(NUM_ACCESSES); // minimum width is 1, NUM_ACCESSES 0 is not valid

reg rd_pending;
reg wr_pending;
reg [COUNT_WIDTH - 1 : 0] cnt; // for counting the accesses to memory system, so we can complete a whole word of wishbone

// Wishbone transaction handling
always @(posedge wb_clk_i) begin // reset is synchronous
  if(wb_rst_i || up_soft_reset) begin // during software microprocessor reset, we also make sure that this block is resetted, as we want to make sure that there are no pending access transactions
    rpg_busy <= 1'b0;
    rpg_st_addr <= {MAIN_MEM_ADDR_WIDTH{1'b0}};
    rpg_burst_length <= {MAIN_MEM_ADDR_WIDTH{1'b0}};
    rd_buff_rden <= 1'b0;
    rd_pending <= 1'b0;
    wpg_busy <= 1'b0;
    wpg_st_addr <= {MAIN_MEM_ADDR_WIDTH{1'b0}};
    wpg_burst_length <= {MAIN_MEM_ADDR_WIDTH{1'b0}};
    wr_buff_wren <= 1'b0;
    wr_buff_wdata <= {MEM_DATA_WIDTH{1'b0}};
    wr_pending <= 1'b0;
    wb_dat_o <= {DATA_WIDTH{1'b0}};
    wb_ack_o <= 1'b0;
    cnt <= {COUNT_WIDTH{1'b0}};
  end else begin
    wb_ack_o <= 1'b0; // Default: no acknowledge
    wpg_busy <= wpg_ack ? 1'b0 : wpg_busy; // automatically release wpg_busy when wpg_ack is seen
    rpg_busy <= rpg_ack ? 1'b0 : rpg_busy; // automatically release rpg_busy when rpg_ack is seen
    rd_buff_rden <= 1'b0;
    if(wb_cyc_i && wb_stb_i && up_en && !wb_ack_o) begin // a new transaction is sent by wishbone master
      if(wb_we_i) begin // Write operation
        wpg_st_addr <= wb_adr_i;
        wpg_burst_length <= 1'b1; // we use classic write operation, as caravel supports classic transactions only
        wr_buff_wdata <= wb_dat_i;
        wr_buff_wren <= 1'b0;
        wr_pending <= 1'b1;
        if(!wr_pending) begin // we set wr_buff_wren, and wpg_busy only once, as the microprocessor writes one single word per transaction
          wpg_busy <= 1'b1;
          wr_buff_wren <= 1'b1;
        end
        if(wpg_ack) begin // once memory system acknowledges that this writing transaction has been attended, we finish the writing transaction on wishbone interface
          wr_pending <= 1'b0;
          wb_ack_o <= 1'b1; // Acknowledge this cycle
        end
      end else begin // read operation
        if(!rd_pending) begin // set only once
          rpg_busy <= 1'b1;
        end
        rpg_st_addr <= wb_adr_i;
        rpg_burst_length <= NUM_ACCESSES; // number of memory words/accesses to complete a whole wishbone word
        rd_pending <= 1'b1;
        if(!rd_buff_empty && !rd_buff_rden) begin // every time a memory word is written into the reading buffer, we sample the data
          rd_buff_rden <= 1'b1;
          //wb_dat_o[cnt*MEM_DATA_WIDTH +: MEM_DATA_WIDTH] <= rd_buff_rdata;
          wb_dat_o <= {wb_dat_o, rd_buff_rdata};
          cnt <= cnt + 1'b1;
          if(cnt == (NUM_ACCESSES - 1)) begin // once memory system acknowledges that reading transaction is done, and all data was written into the reading buffer, we finsih the reading transaction on wishbone interface
            cnt <= {COUNT_WIDTH{1'b0}};
            rd_pending <= 1'b0;
            wb_ack_o <= 1'b1; // Acknowledge this cycle
          end
        end
      end
    end
  end
end

endmodule
