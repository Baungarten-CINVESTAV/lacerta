///////////////////////////////////////////////////////////////////////////////////////
// Company: Mifral
// Engineer: Miguel Rivera
// 
// Design Name: memory_system
// Module Name: buffers_filler
//
// Description:
// this module is responsible for filling the reading buffers, whenever a reading buffer
// is not full, and a burst access is ongoing (as it was read by any consumer), it will
// read the data from the main memory and write it back to given reading buffer.
// this module is responsible for the arbitration of main memory reading accesses
///////////////////////////////////////////////////////////////////////////////////////

module buffers_filler  (
  input wire mem_sys_clk,
  input wire arst_n,
  
  // Read pattern generator //
  input wire [MAIN_MEM_ADDR_WIDTH*NUM_READ_BUFFERS - 1 : 0] rpg_st_addr,
  input wire [MAIN_MEM_ADDR_WIDTH*NUM_READ_BUFFERS - 1 : 0] rpg_burst_length,
  input wire [NUM_READ_BUFFERS - 1 : 0] rpg_busy,
  output reg [NUM_READ_BUFFERS - 1 : 0] rpg_ack,
  output reg [NUM_READ_BUFFERS - 1 : 0] rpg_burst_ongoing,

  // Main memory side //
  output wire main_mem_rden, // Start burst read
  output wire [MAIN_MEM_ADDR_WIDTH - 1 : 0] main_mem_rd_addr, // Starting read address
  input wire [MAIN_MEM_DATA_WIDTH - 1 : 0] main_mem_rd_data, // Data being read
  input wire main_mem_rd_data_valid, // Data being read is valid
  
  // Writing port for reading buffers //
  output reg [NUM_READ_BUFFERS - 1 : 0] rd_buff_wren,
  output reg [MAIN_MEM_DATA_WIDTH*NUM_READ_BUFFERS - 1 : 0] rd_buff_wdata,
  input wire [NUM_READ_BUFFERS - 1 : 0] rd_buff_pre_full,
  input wire [NUM_READ_BUFFERS - 1 : 0] rd_buff_full
);

  localparam STATE_IDLE = 1'b0;
  localparam STATE_WAIT_FULL = 1'b1;

  reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] rpg_st_addr_r [NUM_READ_BUFFERS];
  reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] rpg_st_addr_nxt_r [NUM_READ_BUFFERS];
  reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] rpg_burst_length_r [NUM_READ_BUFFERS];
  reg rpg_burst_start [NUM_READ_BUFFERS];
  reg rpg_burst_done [NUM_READ_BUFFERS];
  reg state;
  reg [$clog2(NUM_READ_BUFFERS)-1:0] rd_buff_sel;
  reg rden_r;
  //integer idx;

  always@(posedge mem_sys_clk, negedge arst_n) begin
    if(!arst_n) begin
      for(integer idx = 0; idx < NUM_READ_BUFFERS; idx = idx + 1) rpg_burst_ongoing[idx] <= 1'b0;
    end else begin
      for(integer idx = 0; idx < NUM_READ_BUFFERS; idx = idx + 1) begin
        if(rpg_burst_start[idx])
          rpg_burst_ongoing[idx] <= 1'b1;
        else if(rpg_burst_done[idx])
          rpg_burst_ongoing[idx] <= 1'b0;
      end
    end
  end

  always@(posedge mem_sys_clk, negedge arst_n) begin
    if(!arst_n) begin
      for(integer idx = 0; idx < NUM_READ_BUFFERS; idx = idx + 1) begin
        rpg_st_addr_r[idx] <= {MAIN_MEM_ADDR_WIDTH{1'b0}};
        rpg_st_addr_nxt_r[idx] <= {MAIN_MEM_ADDR_WIDTH{1'b0}};
        rpg_burst_length_r[idx] <= {MAIN_MEM_ADDR_WIDTH{1'b0}};
      end
    end else begin
      for(integer idx = 0; idx < NUM_READ_BUFFERS; idx = idx + 1) begin
        if(rpg_burst_start[idx]) begin
          rpg_st_addr_r[idx] <= rpg_st_addr[idx*MAIN_MEM_ADDR_WIDTH +: MAIN_MEM_ADDR_WIDTH];
          rpg_st_addr_nxt_r[idx] <= rpg_st_addr[idx*MAIN_MEM_ADDR_WIDTH +: MAIN_MEM_ADDR_WIDTH] + 1'b1;
          rpg_burst_length_r[idx] <= rpg_burst_length[idx*MAIN_MEM_ADDR_WIDTH +: MAIN_MEM_ADDR_WIDTH];
        end else if(rpg_burst_ongoing[idx] && rd_buff_wren[idx] && (rd_buff_sel == idx)) begin
          rpg_st_addr_r[idx] <= rpg_st_addr_r[idx] + 1'b1;
          rpg_st_addr_nxt_r[idx] <= rpg_st_addr_nxt_r[idx] + 1'b1;
          rpg_burst_length_r[idx] <= rpg_burst_length_r[idx] - 1'b1;
        end
      end
    end
  end

  always@(*) begin
    for(integer idx = 0; idx < NUM_READ_BUFFERS; idx = idx + 1) begin
      rpg_burst_start[idx] = rpg_busy[idx] && (!rpg_burst_ongoing[idx]);
      rpg_burst_done[idx] = (rpg_burst_length_r[idx] == {{(MAIN_MEM_ADDR_WIDTH - 1){1'b0}}, 1'b1}) && main_mem_rd_data_valid && (rd_buff_sel == idx);
      rpg_ack[idx] = rpg_burst_done[idx];
    end
  end

  assign main_mem_rd_addr = rpg_st_addr_r[rd_buff_sel];
  assign main_mem_rden = rden_r;

  always@(*) begin
    rd_buff_wren = {NUM_READ_BUFFERS{1'b0}};
    rd_buff_wdata = {MAIN_MEM_DATA_WIDTH*NUM_READ_BUFFERS{1'b0}};
    for(integer idx = 0; idx < NUM_READ_BUFFERS; idx = idx + 1) begin
      if(idx == rd_buff_sel) begin
        if((!rd_buff_full[idx]) && main_mem_rd_data_valid) begin
          rd_buff_wdata[idx*MAIN_MEM_DATA_WIDTH +: MAIN_MEM_DATA_WIDTH] = main_mem_rd_data;
          rd_buff_wren[idx] = 1'b1;
        end
      end
    end
  end

  always@(posedge mem_sys_clk, negedge arst_n) begin
    if(!arst_n) begin
      state <= STATE_IDLE;
      rden_r <= 1'b0;
      rd_buff_sel <= {$clog2(NUM_READ_BUFFERS){1'b0}};
    end else begin

      if(rd_buff_pre_full[rd_buff_sel] || rd_buff_full[rd_buff_sel] || rpg_burst_done[rd_buff_sel])
        rden_r <= 1'b0;

      case(state)

        STATE_IDLE: begin
          for(integer idx = 0; idx < NUM_READ_BUFFERS ; idx = idx + 1) begin // index 0 has the highest priority, we don't want it to get empty
            if((!rd_buff_full[NUM_READ_BUFFERS - 1 - idx]) && rpg_burst_ongoing[NUM_READ_BUFFERS - 1 - idx] && (!(rpg_burst_done[NUM_READ_BUFFERS - 1 - idx]))) begin // rpg buffer must be filled
              rd_buff_sel <= NUM_READ_BUFFERS - 1 - idx;
              rden_r <= 1'b1;
              state <= STATE_WAIT_FULL;
            end
          end
        end

        STATE_WAIT_FULL: begin
          if(rd_buff_pre_full[rd_buff_sel] || rd_buff_full[rd_buff_sel] || rpg_burst_done[rd_buff_sel]) begin // Wait for reading buffer to be full again
            state <= STATE_IDLE;
          end
        end

      endcase

    end
  end


endmodule
