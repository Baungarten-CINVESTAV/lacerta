///////////////////////////////////////////////////////////////////////////////////////
// Company: Mifral
// Engineer: Miguel Rivera
// 
// Design Name: memory_system
// Module Name: buffers_discharger
//
// Description:
// this module is responsible for discharging the writing buffers, whenever
// a writing buffer is not empty (as it was written by any producer), it will
// read the data from the writing buffer and write it back to the main memory.
// this module is responsible for the arbitration of main memory writing
// accesses
///////////////////////////////////////////////////////////////////////////////////////

module buffers_discharger (
  input wire mem_sys_clk,
  input wire arst_n,

  // Write pattern generator //
  input wire [MAIN_MEM_ADDR_WIDTH*NUM_WRITE_BUFFERS - 1 : 0] wpg_st_addr,
  input wire [MAIN_MEM_ADDR_WIDTH*NUM_WRITE_BUFFERS - 1 : 0] wpg_burst_length,
  input wire [NUM_WRITE_BUFFERS - 1 : 0] wpg_busy,
  output reg [NUM_WRITE_BUFFERS - 1 : 0] wpg_ack,

  // Main memory side //
  output wire main_mem_wren,
  output wire [MAIN_MEM_ADDR_WIDTH - 1 : 0] main_mem_wr_addr,
  output reg [MAIN_MEM_DATA_WIDTH - 1 : 0] main_mem_wr_data,
  input wire main_mem_wr_data_ack,
  
  // Reading port for writing buffers //
  output reg [NUM_WRITE_BUFFERS - 1 : 0] wr_buff_rden,
  input wire [MAIN_MEM_DATA_WIDTH*NUM_WRITE_BUFFERS - 1 : 0] wr_buff_rdata,
  input wire [NUM_WRITE_BUFFERS - 1 : 0] wr_buff_pre_empty,
  input wire [NUM_WRITE_BUFFERS - 1 : 0] wr_buff_empty
);

  localparam STATE_IDLE = 1'b0;
  localparam STATE_WAIT_EMPTY = 1'b1;

  reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] wpg_st_addr_r [NUM_WRITE_BUFFERS];
  reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] wpg_burst_length_r [NUM_WRITE_BUFFERS];
  reg wpg_burst_ongoing [NUM_WRITE_BUFFERS];
  reg wpg_burst_start [NUM_WRITE_BUFFERS];
  reg wpg_burst_done [NUM_WRITE_BUFFERS];
  reg state;
  reg [$clog2(NUM_WRITE_BUFFERS-1):0] wr_buff_sel;
  //integer idx;

  always@(posedge mem_sys_clk, negedge arst_n) begin
    if(!arst_n) begin
      for( integer idx = 0; idx < NUM_WRITE_BUFFERS; idx = idx + 1) wpg_burst_ongoing[idx] <= 1'b0;
    end else begin
      for( integer idx = 0; idx < NUM_WRITE_BUFFERS; idx = idx + 1) begin
        if(wpg_burst_start[idx])
          wpg_burst_ongoing[idx] <= 1'b1;
        else if(wpg_burst_done[idx])
          wpg_burst_ongoing[idx] <= 1'b0;
      end
    end
  end

  always@(posedge mem_sys_clk, negedge arst_n) begin
    if(!arst_n) begin
      for( integer idx = 0; idx < NUM_WRITE_BUFFERS; idx = idx + 1) begin
        wpg_st_addr_r[idx] <= {MAIN_MEM_ADDR_WIDTH{1'b0}};
        wpg_burst_length_r[idx] <= {MAIN_MEM_ADDR_WIDTH{1'b0}};
      end
    end else begin
      for( integer idx = 0; idx < NUM_WRITE_BUFFERS; idx = idx + 1) begin
        if(wpg_burst_start[idx]) begin
          wpg_st_addr_r[idx] <= wpg_st_addr[idx*MAIN_MEM_ADDR_WIDTH +: MAIN_MEM_ADDR_WIDTH];
          wpg_burst_length_r[idx] <= wpg_burst_length[idx*MAIN_MEM_ADDR_WIDTH +: MAIN_MEM_ADDR_WIDTH];
        end else if(wpg_burst_ongoing[idx] && main_mem_wr_data_ack && (wr_buff_sel == idx)) begin
          wpg_st_addr_r[idx] <= wpg_st_addr_r[idx] + 1'b1;
          wpg_burst_length_r[idx] <= wpg_burst_length_r[idx] - 1'b1;
        end
      end
    end
  end

  always@(*) begin
    for( integer idx = 0; idx < NUM_WRITE_BUFFERS; idx = idx + 1) begin
      wpg_burst_start[idx] = wpg_busy[idx] && (!wpg_burst_ongoing[idx]);
      wpg_burst_done[idx] = (wpg_burst_length_r[idx] == {{(MAIN_MEM_ADDR_WIDTH - 1){1'b0}},1'b1}) && wpg_burst_ongoing[idx] && main_mem_wr_data_ack && (wr_buff_sel == idx);
      wpg_ack[idx] = wpg_burst_done[idx];
    end
  end

  assign main_mem_wr_addr = wpg_st_addr_r[wr_buff_sel];

  always@(*) begin
    main_mem_wr_data = {MAIN_MEM_DATA_WIDTH{1'b0}};
    wr_buff_rden = {NUM_WRITE_BUFFERS{1'b0}};
    for( integer idx = 0; idx < NUM_WRITE_BUFFERS; idx = idx + 1) begin
      if(wr_buff_sel == idx) begin
        if((!wr_buff_empty[idx]) && main_mem_wr_data_ack && main_mem_wren && (!wpg_burst_start[idx])) begin
          wr_buff_rden[wr_buff_sel] = 1'b1;
        end
        main_mem_wr_data = wr_buff_rdata[wr_buff_sel*MAIN_MEM_DATA_WIDTH +: MAIN_MEM_DATA_WIDTH];
      end
    end
  end

  assign main_mem_wren = state == STATE_WAIT_EMPTY && (!wr_buff_empty[wr_buff_sel]) && (!wpg_burst_start[wr_buff_sel]) && wpg_burst_ongoing[wr_buff_sel];

  always@(posedge mem_sys_clk, negedge arst_n) begin
    if(!arst_n) begin
      state <= STATE_IDLE;
      wr_buff_sel <= 'd0;
    end else begin

      case(state)

        STATE_IDLE: begin
          for( integer idx = 0; idx < NUM_WRITE_BUFFERS; idx = idx + 1) begin
            if((!wr_buff_empty[idx]) && wpg_burst_ongoing[idx]) begin // buffer must be discharged
              wr_buff_sel <= idx;
              state <= STATE_WAIT_EMPTY;
            end
          end
        end

        STATE_WAIT_EMPTY: begin
          if(wr_buff_pre_empty[wr_buff_sel] || wr_buff_empty[wr_buff_sel] || wpg_burst_done[wr_buff_sel]) begin // Wait for writing buffer to be empty again
            state <= STATE_IDLE;
          end
        end

      endcase

    end
  end

endmodule
