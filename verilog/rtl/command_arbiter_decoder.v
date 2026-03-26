module command_arbiter_decoder(
	input wire clk,
	input wire arst_n,
	output reg [20:0] conf_logics_0,
	output reg [20:0] conf_logics_1,
	// write pattern generator and writing buffer signals (driven by commands coming from uart)
	input wire host_wpg_ack,
	output reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] host_wpg_st_addr,
	output reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] host_wpg_burst_length,
	output reg host_wpg_busy,
	output reg host_wr_buff_wren,
	output reg [MAIN_MEM_DATA_WIDTH - 1 : 0] host_wr_buff_wdata,
	input wire host_wr_buff_full,
	// read pattern generator and reading buffer signals (driven by commands coming from uart)
	output reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] host_rpg_st_addr,
	output reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] host_rpg_burst_length,
	output reg host_rpg_busy,
	input wire host_rpg_ack,
	output wire host_rd_buff_rden,
	input wire [MAIN_MEM_DATA_WIDTH - 1 : 0] host_rd_buff_rdata,
	input wire host_rd_buff_empty,
	// signals to control drawing circuit, and trigger enabling and resetting for microprocessor
  output reg [3:0] obj_type, // 0 - boolean, 1 vertical incremental, 2 horizontal incremental
  output reg [10:0] obj_width,
  output reg [10:0] obj_height,
  output reg [21:0] obj_st_pix, // starting pixel
  output reg [21:0] obj_st_mask,
  output reg [14:0] obj_value,
	output reg drw_inc_start,
	input wire drw_inc_busy,
	output reg wb_slave_up_en,
	output reg up_soft_reset,
	output reg up_soft_reset_req,
	// uart signals to control memory reading and writing port
	input wire uart_mem_we,
	input wire [UART_BYTES_DATA * 8 - 1 : 0] uart_mem_wdata,
	input wire [UART_BYTES_ADDRESS * 8 - 1 : 0] uart_mem_waddr,
	input wire uart_mem_re,
	input wire [UART_BYTES_ADDRESS * 8 - 1 : 0] uart_mem_raddr,
	output wire [UART_BYTES_DATA * 8 - 1 : 0] uart_mem_rdata,
	output wire uart_mem_rdy,
	// microprocessor wishbone signals to control memory reading and writing port
	input wire wb_slave_mem_we,
	input wire [WB_DATA_WIDTH - 1 : 0] wb_slave_mem_wdata,
	input wire [(WB_DATA_WIDTH/8) - 1 : 0] wb_slave_mem_wmask,
	input wire [WB_ADDR_WIDTH - 1 : 0] wb_slave_mem_waddr,
	output reg wb_slave_mem_wr_data_ack,
	input wire wb_slave_mem_re,
	input wire [WB_ADDR_WIDTH - 1 : 0] wb_slave_mem_raddr,
	output reg [WB_DATA_WIDTH - 1 : 0] wb_slave_mem_rdata,
	output reg wb_slave_mem_rdy,
	input wire wb_mem_sys_wb_ack_o 
);


// TODO: need to move this logic into a new block, where we can start the drawing circuit from either wishbone or uart
always@(posedge clk, negedge arst_n) begin
  if(!arst_n) begin
    host_wpg_st_addr <= {MAIN_MEM_ADDR_WIDTH{1'b0}};
    host_wpg_burst_length <= {MAIN_MEM_ADDR_WIDTH{1'b0}};
    host_wpg_busy <= 1'b0;
    host_rpg_st_addr <= {MAIN_MEM_ADDR_WIDTH{1'b0}};
    host_rpg_burst_length <= {MAIN_MEM_ADDR_WIDTH{1'b0}};
    host_rpg_busy <= 1'b0;
    host_wr_buff_wren <= 1'b0;
    host_wr_buff_wdata <= {MAIN_MEM_DATA_WIDTH{1'b0}};
    conf_logics_0 <= {H_SYNC_DEACT[9:0], H_SYNC_ACT[10:0]};
    conf_logics_1 <= {V_SYNC_DEACT[9:0], V_SYNC_ACT[10:0]};
    obj_type <= 4'd0;
    obj_width <= 11'd0;
    obj_height <= 11'd0;
    obj_st_pix <= 22'd0;
    obj_st_mask <= 22'd0;
    obj_value <= 15'd0;
    drw_inc_start <= 1'b0;
    wb_slave_mem_wr_data_ack <= 1'b0;
    wb_slave_mem_rdy <= 1'b0;
    wb_slave_mem_rdata <= {WB_DATA_WIDTH{1'b0}};
    wb_slave_up_en <= 1'b0;
    up_soft_reset <= 1'b0;
    up_soft_reset_req <= 1'b0;
  end else begin
    
    if(!host_wr_buff_full)
      host_wr_buff_wren <= 1'b0;
    
    drw_inc_start <= 1'b0;
    
    if(host_wpg_ack)
      host_wpg_busy <= 1'b0;
    if(host_rpg_ack)
      host_rpg_busy <= 1'b0;

    if(uart_mem_we) begin // A new write from UART is seen
      up_soft_reset <= 1'b0; // we release reset by receiving a new command from uart
      case(uart_mem_waddr)
        0: begin host_wpg_st_addr <= uart_mem_wdata[MAIN_MEM_ADDR_WIDTH - 1 : 0]; end
        1: begin host_wpg_burst_length <= uart_mem_wdata[MAIN_MEM_ADDR_WIDTH - 1 : 0]; end
        2: begin host_wpg_busy <= 1'b1; end
        3: begin host_rpg_st_addr <= uart_mem_wdata[MAIN_MEM_ADDR_WIDTH - 1 : 0]; end
        4: begin host_rpg_burst_length <= uart_mem_wdata[MAIN_MEM_ADDR_WIDTH - 1 : 0]; end
        5: begin host_rpg_busy <= 1'b1; end
        6: begin host_wr_buff_wren <= 1'b1; host_wr_buff_wdata <= uart_mem_wdata; end
        7: begin conf_logics_0 <= uart_mem_wdata; end
        8: begin conf_logics_1 <= uart_mem_wdata; end
        9: begin conf_logics_0 <= uart_mem_wdata; end // TODO: remove
        10: begin conf_logics_1 <= uart_mem_wdata; end // TODO: remove
        11: begin drw_inc_start <= 1'b1; obj_value <= uart_mem_wdata; end
        12: begin obj_type <= uart_mem_wdata; end
        13: begin obj_width <= uart_mem_wdata; end
        14: begin obj_height <= uart_mem_wdata; end
        15: begin obj_st_pix <= uart_mem_wdata; end
        16: begin obj_st_mask <= uart_mem_wdata; end
        17: begin up_soft_reset_req <= 1'b1; end // we only assert microprocessor software reset request if micro processor is enabled
        18: begin wb_slave_up_en <= 1'b1; end 
      endcase
    end

    wb_slave_mem_wr_data_ack <= 1'b0;
    wb_slave_mem_rdy <= 1'b0;
    
    if(wb_slave_mem_we) begin // A new write from wishbone is seen
      wb_slave_mem_wr_data_ack <= 1'b1;
      case(wb_slave_mem_waddr[WB_ADDR_WIDTH - 5 : 0])
        28: begin conf_logics_0 <= wb_slave_mem_wdata; end
        32: begin conf_logics_1 <= wb_slave_mem_wdata; end
        36: begin conf_logics_0 <= wb_slave_mem_wdata; end // TODO: remove
        40: begin conf_logics_1 <= wb_slave_mem_wdata; end // TODO: remove
        44: begin drw_inc_start <= 1'b1; obj_value <= wb_slave_mem_wdata;end
        48: begin obj_type <= wb_slave_mem_wdata;end
        52: begin obj_width <= wb_slave_mem_wdata;end
        56: begin obj_height <= wb_slave_mem_wdata;end
        60: begin obj_st_pix <= wb_slave_mem_wdata;end
        64: begin obj_st_mask <= wb_slave_mem_wdata;end
      endcase
    end

    if(wb_slave_mem_re) begin // A new write from wishbone is seen
      case(wb_slave_mem_raddr[WB_ADDR_WIDTH - 5 : 0])
        0: begin wb_slave_mem_rdata <= drw_inc_busy; wb_slave_mem_rdy <= 1'b1; end
      endcase
    end

    if(up_soft_reset_req && (wb_mem_sys_wb_ack_o || (!wb_slave_up_en)) && (!drw_inc_busy) && (!drw_inc_start)) begin // we assert the up_soft_reset only if there is no pending memory access to main memory from the microprocessor
			wb_slave_up_en <= 1'b0;
      up_soft_reset_req <= 1'b0;
      up_soft_reset <= 1'b1;
    end

  end
end

assign host_rd_buff_rden = uart_mem_re;
assign uart_mem_rdata = host_rd_buff_rdata;
assign uart_mem_rdy = 1'b1; // !host_rd_buff_empty;

endmodule 
