///////////////////////////////////////////////////////////////////////////////////////
// Company: Mifral
// Engineer: Miguel Rivera
// 
// Design Name: lacerta
// Module Name: screen_system
//
// Description:
// this module wraps the spi_master, color_mapping_table, and tft_control_fsm
// modules, this module is the top module of the screen system
///////////////////////////////////////////////////////////////////////////////////////

module screen_system (
  input wire clk,
  input wire arst_n,
  input wire ss_wren_reg,
  input wire [$clog2(SCREEN_INIT_MEM_SIZE) - 1 : 0] ss_wraddr_reg,
  input wire [9 : 0] ss_wrdata_reg,
  input wire initialize,
  input wire [5 : 0] clock_divider,
  input wire cm_wren,
  input wire [$clog2(COLOR_MAP_NUM) - 1 : 0] cm_addr,
  input wire [15 : 0] cm_data, // 16 bits per pixel RGB565
  input wire ss_ld_sidebar,
  // signals going to lacerta to fetch pixel values from memory system
  output wire [MAIN_MEM_ADDR_WIDTH - 1 : 0] rpg_st_addr,
  output wire [MAIN_MEM_ADDR_WIDTH - 1 : 0] rpg_burst_length,
  output wire rpg_busy,
  output wire rd_buff_rden,
  input wire rpg_ack,
  input wire [MAIN_MEM_DATA_WIDTH - 1 : 0] rd_buff_rdata,
  input wire rd_buff_empty,
  // signals coming from lacerta to update pixels
  input wire fetch_frame,
  input wire [9 : 0] frame_st_x,
  input wire [9 : 0] frame_end_x,
  input wire [MAXIMUM_INCREMENTAL_WIDTH_BITS - 1 : 0] frame_width,
  input wire [9 : 0] frame_st_y,
  input wire [9 : 0] frame_end_y,
  input wire [MAXIMUM_INCREMENTAL_HEIGHT_BITS - 1 : 0] frame_height,
  input wire [MAIN_MEM_ADDR_WIDTH - 1 : 0] frame_st_pix,
  output wire done,
  output wire busy,
  // SPI ports
  output wire sck,
  output wire ss,
  output wire mosi,
  // data/command send to tft screen
  output wire dc,
  output wire res
);

  // SPI master control ports
  wire tnsm;
  wire [7 : 0] tnsm_data;
  wire tnsm_busy;
  wire tnsm_ack;
  wire tnsm_done;

  wire [$clog2(COLOR_MAP_NUM) - 1 : 0] color_sel;
  wire [15 : 0] color;

tft_control_fsm tft_control_fsm_i (
  .clk(clk),
  .arst_n(arst_n),
  .initialize(initialize), // this will be set when the tft screen initialization process should begin
  // SPI master control ports
  .tnsm(tnsm),
  .tnsm_data(tnsm_data),
  .tnsm_busy(tnsm_busy),
  .tnsm_ack(tnsm_ack),
  .tnsm_done(tnsm_done),
  // signals going to lacerta to fetch pixel values from memory system
  .rpg_st_addr(rpg_st_addr),
  .rpg_burst_length(rpg_burst_length),
  .rpg_busy(rpg_busy),
  .rpg_ack(rpg_ack),
  .rd_buff_rden(rd_buff_rden),
  .rd_buff_rdata(rd_buff_rdata),
  .rd_buff_empty(rd_buff_empty),
  // signals to color mapping
  .color_sel(color_sel),
  .color(color),
  // signals coming from lacerta to write into the initialization memory
  .ss_wren_reg(ss_wren_reg),
  .ss_wraddr_reg(ss_wraddr_reg),
  .ss_wrdata_reg(ss_wrdata_reg),
  // signals coming from lacerta to update pixels
  .fetch_frame(fetch_frame),
  .frame_st_x(frame_st_x),
  .frame_end_x(frame_end_x),
  .frame_width(frame_width),
  .frame_st_y(frame_st_y),
  .frame_end_y(frame_end_y),
  .frame_height(frame_height),
  .frame_st_pix(frame_st_pix),
  .ss_ld_sidebar(ss_ld_sidebar),
  .done(done),
  .busy(busy),
  // data/command send to tft screen
  .dc(dc),
  .res(res)
);

spi_master spi_master_i (
  .clk(clk),
  .arst_n(arst_n),
  // Control ports
  .clock_divider(clock_divider),
  .tnsm(tnsm),
  .tnsm_data(tnsm_data),
  .tnsm_ack(tnsm_ack),
  .tnsm_busy(tnsm_busy),
  .tnsm_done(tnsm_done),
  // SPI ports
  .sck(sck),
  .ss(ss),
  .mosi(mosi)
);

color_mapping_table color_mapping_table_i (
  .clk(clk),
  .arst_n(arst_n),
  .cm_wren(cm_wren),
  .cm_addr(cm_addr),
  .cm_data(cm_data), // 16 bits per pixel RGB565
  .color_sel(color_sel),
  .color(color)
);

endmodule
