///////////////////////////////////////////////////////////////////////////////////////
// Company: Mifral
// Engineer: Miguel Rivera
// 
// Design Name: lacerta
// Module Name: command_arbiter_decoder
//
// Description:
// this module is responsible of decoding the commands coming from either the uart
// subsystem, or from rv microprocessor, these commands, including accesses to
// the main memory, mask generator circuit, color map configuration, and screen system
///////////////////////////////////////////////////////////////////////////////////////

module command_arbiter_decoder(
  input wire clk,
  input wire arst_n,
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
  output reg [3 : 0] obj_type, // 0 - boolean, 1 vertical incremental, 2 horizontal incremental
  output reg [MAXIMUM_INCREMENTAL_WIDTH_BITS - 1 : 0] obj_width, // object width
  output reg [MAXIMUM_INCREMENTAL_HEIGHT_BITS - 1 : 0] obj_height, // object height
  output reg [9 : 0] obj_st_x, // object starting x coordinate in the screen
  output reg [9 : 0] obj_st_y, // object starting y coordinate in the screen
  output reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] obj_st_pix, // starting pixel address in external memory
  output reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] obj_st_mask, // starting mask address in external memory
  output reg [9 : 0] obj_value, // object value for updating the object in the screen
  output reg drw_inc_start,
  input wire drw_inc_busy,
  output reg wb_slave_up_en,
  output reg up_soft_reset,
  output reg up_soft_reset_req,
  // screen system signals
  input wire ss_busy,
  output reg ss_wren_reg,
  output reg ss_start, // this can be used to start the refreshing of the screen system without requiring the trigger of the drawing circuit (from uart/wishbone)
  output reg [$clog2(SCREEN_INIT_MEM_SIZE) - 1 : 0] ss_wraddr_reg, // 64 entries on initialization ram
  output reg [9 : 0] ss_wrdata_reg, // 2 bits for byte type, and 8 bits for data/command
  output reg ss_initialize, // screen system initialize
  output reg [5 : 0] ss_clock_divider, // screen system clock divider
  output reg cm_wren,
  output reg [$clog2(COLOR_MAP_NUM) - 1 : 0] cm_addr,
  output reg [15 : 0] cm_data,
  output reg ss_ld_sidebar,
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
    obj_type <= 4'd0;
    obj_width <= {MAXIMUM_INCREMENTAL_WIDTH_BITS{1'b0}};
    obj_height <= {MAXIMUM_INCREMENTAL_HEIGHT_BITS{1'b0}};
    obj_st_x <= 10'd0;
    obj_st_y <= 10'd0;
    obj_st_pix <= {MAIN_MEM_ADDR_WIDTH{1'b0}};
    obj_st_mask <= {MAIN_MEM_ADDR_WIDTH{1'b0}};
    obj_value <= 10'd0;
    drw_inc_start <= 1'b0;
    wb_slave_mem_wr_data_ack <= 1'b0;
    wb_slave_mem_rdy <= 1'b0;
    wb_slave_mem_rdata <= {WB_DATA_WIDTH{1'b0}};
    wb_slave_up_en <= 1'b0;
    up_soft_reset <= 1'b0;
    up_soft_reset_req <= 1'b0;
    ss_start <= 1'b0;
    ss_wren_reg <= 1'b0;
    ss_wraddr_reg <= 6'd0;
    ss_wrdata_reg <= 10'd0;
    ss_initialize <= 1'b0;
    ss_clock_divider <= 6'd5; // 5 by default
    cm_wren <= 1'b0;
    cm_addr <= {$clog2(COLOR_MAP_NUM){1'b0}};
    cm_data <= 16'd0;
    ss_ld_sidebar <= 1'b0;
  end else begin

    if(!host_wr_buff_full) // this should be technically impossible to happen, as host is written by uart, which is very slow protocol
      host_wr_buff_wren <= 1'b0;
    
    drw_inc_start <= 1'b0; // this should be a pulse
    ss_initialize <= 1'b0; // this should be a pulse
    ss_wren_reg <= 1'b0; // this should be a pulse
    ss_start <= 1'b0; // this should be a pulse
    cm_wren <= 1'b0; // this should be a pulse
    ss_ld_sidebar <= 1'b0; // this should be a pulse

    if(host_wpg_ack) // we do only one burst write access per uart/wb request
      host_wpg_busy <= 1'b0;
    if(host_rpg_ack) // we do only one burst read access per uart/wb request
      host_rpg_busy <= 1'b0;

    if(uart_mem_we) begin // A new write from UART is seen
      up_soft_reset <= 1'b0; // we release microprocessor reset when receiving a new command from uart
      case(uart_mem_waddr)
        0: begin host_wpg_st_addr <= uart_mem_wdata[MAIN_MEM_ADDR_WIDTH - 1 : 0]; end
        1: begin host_wpg_burst_length <= uart_mem_wdata[MAIN_MEM_ADDR_WIDTH - 1 : 0]; end
        2: begin host_wpg_busy <= 1'b1; end
        3: begin host_rpg_st_addr <= uart_mem_wdata[MAIN_MEM_ADDR_WIDTH - 1 : 0]; end
        4: begin host_rpg_burst_length <= uart_mem_wdata[MAIN_MEM_ADDR_WIDTH - 1 : 0]; end
        5: begin host_rpg_busy <= 1'b1; end
        6: begin host_wr_buff_wren <= 1'b1; host_wr_buff_wdata <= uart_mem_wdata; end
        7: begin drw_inc_start <= 1'b1; obj_value <= uart_mem_wdata; end
        8: begin obj_type <= uart_mem_wdata; end
        9: begin obj_width <= uart_mem_wdata; end
        10: begin obj_height <= uart_mem_wdata; end
        11: begin obj_st_pix <= uart_mem_wdata; end
        12: begin obj_st_mask <= uart_mem_wdata; end
        13: begin obj_st_x <= uart_mem_wdata; end
        14: begin obj_st_y <= uart_mem_wdata; end
        15: begin up_soft_reset_req <= 1'b1; end // we only assert microprocessor software reset request if micro processor is enabled
        16: begin wb_slave_up_en <= 1'b1; end 
        17: begin ss_clock_divider <= uart_mem_wdata; end
        18: begin ss_initialize <= 1'b1; end
        19: begin ss_wren_reg <= 1'b1; ss_wraddr_reg <= uart_mem_wdata[5 : 0]; ss_wrdata_reg <= uart_mem_wdata[15 : 6]; end
        20: begin ss_start <= 1'b1; end
        21: begin cm_wren <= 1'b1; cm_addr <= uart_mem_wdata[$clog2(COLOR_MAP_NUM) - 1 : 0]; cm_data <= uart_mem_wdata[16 + $clog2(COLOR_MAP_NUM) - 1 : $clog2(COLOR_MAP_NUM)]; end
        22: begin ss_ld_sidebar <= 1'b1; end
        default: begin end // do nothing
      endcase
    end

    wb_slave_mem_wr_data_ack <= 1'b0; // this should be a pulse
    wb_slave_mem_rdy <= 1'b0; // this should be a pulse
    
    if(wb_slave_mem_we) begin // A new write request from wishbone is seen
      wb_slave_mem_wr_data_ack <= 1'b1; // we acknowledge that write request from wishbone is attended
      case(wb_slave_mem_waddr[7 : 0]) // using 8 bits only, as we don't need to check for all address bits
        0: begin drw_inc_start <= 1'b1; obj_value <= wb_slave_mem_wdata;end // as picorv is byte addressable, our addresses must be aligned
        4: begin obj_type <= wb_slave_mem_wdata;end
        8: begin obj_width <= wb_slave_mem_wdata;end
        12: begin obj_height <= wb_slave_mem_wdata;end
        16: begin obj_st_pix <= wb_slave_mem_wdata;end
        20: begin obj_st_mask <= wb_slave_mem_wdata;end
        24: begin obj_st_x <= wb_slave_mem_wdata; end
        28: begin obj_st_y <= wb_slave_mem_wdata; end
        32: begin ss_clock_divider <= wb_slave_mem_wdata; end
        36: begin ss_initialize <= 1'b1; end
        40: begin ss_wren_reg <= 1'b1; ss_wraddr_reg <= wb_slave_mem_wdata[5 : 0]; ss_wrdata_reg <= wb_slave_mem_wdata[15 : 6]; end
        44: begin ss_start <= 1'b1; end
        48: begin cm_wren <= 1'b1; cm_addr <= wb_slave_mem_wdata[$clog2(COLOR_MAP_NUM) - 1 : 0]; cm_data <= wb_slave_mem_wdata[16 + $clog2(COLOR_MAP_NUM) - 1 : $clog2(COLOR_MAP_NUM)]; end
        52: begin ss_ld_sidebar <= 1'b1; end
        default: begin end // do nothing
      endcase
    end
    
    if(wb_slave_mem_re) begin // A new read request from wishbone is seen
      case(wb_slave_mem_raddr[7 : 0]) // using 8 bits only, as we don't need to check for all address bits
        0: begin wb_slave_mem_rdata <= {ss_busy, drw_inc_busy}; wb_slave_mem_rdy <= 1'b1; end // when read from up, we check if either the drawing or the screen system are busy, so we can send a new command
        default: begin end // do nothing
      endcase
    end
    
    if(up_soft_reset_req && (wb_mem_sys_wb_ack_o || (!wb_slave_up_en)) && (!(drw_inc_busy || ss_busy)) && (!drw_inc_start)) begin // we assert the up_soft_reset only if there is no pending memory access to main memory from the microprocessor
      wb_slave_up_en <= 1'b0;
      up_soft_reset_req <= 1'b0;
      up_soft_reset <= 1'b1;
    end
  
  end
end

assign host_rd_buff_rden = uart_mem_re;
assign uart_mem_rdata = host_rd_buff_rdata;
assign uart_mem_rdy = 1'b1; // data not being ready should be technically impossible to happen, as host read is performed by uart, which is very slow protocol

endmodule
