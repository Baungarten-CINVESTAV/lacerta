module dig_top (
  input wire clk,
  input wire arst_n,

  // uprocessor interface
  output wire up_soft_reset,

  // UART interface
  input wire rx,
  output wire tx,
    
  // Wishbone interface
  input wire [WB_ADDR_WIDTH-1:0]     	wb_adr_i, // Address input
  input wire [WB_DATA_WIDTH-1:0]     	wb_dat_i, // Data input
  output reg [WB_DATA_WIDTH-1:0]     	wb_dat_o, // Data output
  input wire                    			wb_we_i,  // Write enable
  input wire [(WB_DATA_WIDTH/8)-1:0] 	wb_sel_i, // Byte select
  input wire                      		wb_stb_i, // Strobe
  input wire                      		wb_cyc_i, // Cycle valid
  output reg                      		wb_ack_o,  // Acknowledge

  // SRAM interface
  output wire [MAIN_MEM_ADDR_WIDTH-1:0] sram_addr,
  output wire [MAIN_MEM_DATA_WIDTH-1:0] sram_data,
  output wire sram_ce_n,
  output wire sram_oe_n,
  output wire sram_we_n,
  output wire sram_lb_n,

  // TFT ports
  output wire sck,
  output wire ss,
  output wire mosi,
  // data/command send to tft screen
  output wire dc,
  output wire res,
  output wire blk
);

assign sram_lb_n = 1'b0; // TODO: temporal for fpga only

localparam SS_READ_BUFFER_NUMBER = 0;
localparam HOST_READ_BUFFER_NUMBER = 1;
localparam HOST_WRITE_BUFFER_NUMBER = 0;
localparam DRAW_READ_BUFFER_NUMBER = 2;
localparam DRAW_WRITE_BUFFER_NUMBER = 1;
localparam WB_READ_BUFFER_NUMBER = 3;
localparam WB_WRITE_BUFFER_NUMBER = 2;

// ======================================================================================================= //
// ===================================== host memory accessing signals =================================== //
// ======================================================================================================= //
// uart signals to control memory reading and writing port
wire uart_mem_we;
wire [UART_BYTES_DATA * 8 - 1 : 0] uart_mem_wdata;
wire [UART_BYTES_ADDRESS * 8 - 1 : 0] uart_mem_waddr;
wire uart_mem_re;
wire [UART_BYTES_ADDRESS * 8 - 1 : 0] uart_mem_raddr;
wire [UART_BYTES_DATA * 8 - 1 : 0] uart_mem_rdata;
wire uart_mem_rdy;

// write pattern generator and writing buffer signals (driven by commands coming from uart)
wire [MAIN_MEM_ADDR_WIDTH - 1 : 0] host_wpg_st_addr;
wire [MAIN_MEM_ADDR_WIDTH - 1 : 0] host_wpg_burst_length;
wire host_wpg_busy;
reg host_wpg_ack;
wire host_wr_buff_wren;
wire [MAIN_MEM_DATA_WIDTH - 1 : 0] host_wr_buff_wdata;
reg host_wr_buff_full;

// read pattern generator and reading buffer signals (driven by commands coming from uart)
wire [MAIN_MEM_ADDR_WIDTH - 1 : 0] host_rpg_st_addr;
wire [MAIN_MEM_ADDR_WIDTH - 1 : 0] host_rpg_burst_length;
wire host_rpg_busy;
reg host_rpg_ack;
wire host_rd_buff_rden;
reg [MAIN_MEM_DATA_WIDTH - 1 : 0] host_rd_buff_rdata;
reg host_rd_buff_empty;

// ======================================================================================================= //
// =============================== caravel wishbone memory accessing signals ============================= //
// ======================================================================================================= //
// microprocessor enabled, the memory system will acknowledge the accesses requests from picorv, only when this signal is set
wire up_soft_reset_req;
wire wb_slave_up_en;
// uart signals to control memory reading and writing port
wire wb_slave_mem_we;
wire [WB_DATA_WIDTH - 1 : 0] wb_slave_mem_wdata;
wire [(WB_DATA_WIDTH/8) - 1 : 0] wb_slave_mem_wmask;
wire [WB_ADDR_WIDTH - 1 : 0] wb_slave_mem_waddr;
wire wb_slave_mem_wr_data_ack;
wire wb_slave_mem_re;
wire [WB_ADDR_WIDTH - 1 : 0] wb_slave_mem_raddr;
wire [WB_DATA_WIDTH - 1 : 0] wb_slave_mem_rdata;
wire wb_slave_mem_rdy;

reg wb_transaction_type; // 1 if wishbone transaction is directed to drawing control logic (mmio), 0 if transaction is directed to memory system accessing
wire [WB_DATA_WIDTH-1:0] wb_mem_sys_wb_dat_o;
wire [WB_DATA_WIDTH-1:0] wb_ctrl_wb_dat_o;
wire wb_mem_sys_wb_ack_o;
wire wb_ctrl_wb_ack_o;
// read pattern generator related signals
wire [MAIN_MEM_ADDR_WIDTH - 1 : 0] wb_slave_rpg_st_addr;
wire [MAIN_MEM_ADDR_WIDTH - 1 : 0] wb_slave_rpg_burst_length;
wire wb_slave_rpg_busy;
reg wb_slave_rpg_ack;
// reading buffer related signals
wire wb_slave_rd_buff_rden;
reg [MAIN_MEM_DATA_WIDTH - 1 : 0] wb_slave_rd_buff_rdata;
reg wb_slave_rd_buff_empty;

// write pattern generator signals
wire [MAIN_MEM_ADDR_WIDTH - 1 : 0] wb_slave_wpg_st_addr;
wire [MAIN_MEM_ADDR_WIDTH - 1 : 0] wb_slave_wpg_burst_length;
wire wb_slave_wpg_busy;
reg wb_slave_wpg_ack;
// Writing port for writing buffers //
wire wb_slave_wr_buff_wren;
wire [MAIN_MEM_DATA_WIDTH - 1 : 0] wb_slave_wr_buff_wdata;
reg wb_slave_wr_buff_full;

// ======================================================================================================= //
// ======================================== screen system signals ======================================== //
// ======================================================================================================= //
wire ss_initialize;
wire [5 : 0] ss_clock_divider;
wire ss_start;
wire ss_start_cdec;
wire ss_wren_reg;
wire [$clog2(SCREEN_INIT_MEM_SIZE) - 1 : 0] ss_wraddr_reg;
wire [9 : 0] ss_wrdata_reg;
wire cm_wren;
wire [$clog2(COLOR_MAP_NUM) - 1 : 0] cm_addr;
wire [15 : 0] cm_data;
wire ss_done;
wire ss_busy;
reg fetch_frame;
reg [9 : 0] frame_st_x;
reg [9 : 0] frame_end_x;
reg [MAXIMUM_INCREMENTAL_WIDTH_BITS - 1 : 0] frame_width;
reg [9 : 0] frame_st_y;
reg [9 : 0] frame_end_y;
reg [MAXIMUM_INCREMENTAL_HEIGHT_BITS - 1 : 0] frame_height;
reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] frame_st_pix;
wire [MAIN_MEM_ADDR_WIDTH - 1 : 0] ss_rpg_st_addr;
wire [MAIN_MEM_ADDR_WIDTH - 1 : 0] ss_rpg_burst_length;
wire ss_rpg_busy;
reg ss_rpg_ack;
wire ss_rd_buff_rden;
reg [MAIN_MEM_DATA_WIDTH - 1 : 0] ss_rd_buff_rdata;
reg ss_rd_buff_empty;
wire ss_ld_sidebar;

// ======================================================================================================= //
// ===================================== drawing incremental signals ===================================== //
// ======================================================================================================= //
wire drw_inc_start;
wire [3:0] obj_type; // 0 - boolean, 1 vertical incremental, 2 horizontal incremental
wire [MAXIMUM_INCREMENTAL_WIDTH_BITS - 1 : 0] obj_width;
wire [MAXIMUM_INCREMENTAL_HEIGHT_BITS - 1 : 0] obj_height;
wire [9 : 0] obj_st_x;
wire [9 : 0] obj_st_y;
wire [MAIN_MEM_ADDR_WIDTH - 1 : 0] obj_st_pix; // starting pixel
wire [MAIN_MEM_ADDR_WIDTH - 1 : 0] obj_st_mask;
wire [9 : 0] obj_value;
wire [MAIN_MEM_ADDR_WIDTH - 1 : 0] drw_inc_rpg_st_addr;
wire [MAIN_MEM_ADDR_WIDTH - 1 : 0] drw_inc_rpg_burst_length;
wire drw_inc_rpg_busy;
reg drw_inc_rpg_ack;
wire drw_inc_rd_buff_rden;
reg [MAIN_MEM_DATA_WIDTH - 1 : 0] drw_inc_rd_buff_rdata;
reg drw_inc_rd_buff_empty;
wire [MAIN_MEM_ADDR_WIDTH - 1 : 0] drw_inc_wpg_st_addr;
wire [MAIN_MEM_ADDR_WIDTH - 1 : 0] drw_inc_wpg_burst_length;
wire drw_inc_wpg_busy;
reg drw_inc_wpg_ack;
wire drw_inc_wr_buff_wren;
wire [MAIN_MEM_DATA_WIDTH - 1 : 0] drw_inc_wr_buff_wdata;
reg drw_inc_wr_buff_full;
wire drw_inc_busy;
wire drw_inc_done;

// ======================================================================================================= //
// ======================================== Memory system signals ======================================== //
// ======================================================================================================= //
// Main memory signals
// Reading port //
wire main_mem_rden;
wire [MAIN_MEM_ADDR_WIDTH - 1 : 0] main_mem_rd_addr;
wire [MAIN_MEM_DATA_WIDTH - 1 : 0] main_mem_rd_data;
wire main_mem_rd_data_valid;

// Writing port //
wire main_mem_wren;
wire [MAIN_MEM_ADDR_WIDTH - 1 : 0] main_mem_wr_addr;
wire [MAIN_MEM_DATA_WIDTH - 1 : 0] main_mem_wr_data;
wire main_mem_wr_data_ack;

// write pattern generator signals
reg [MAIN_MEM_ADDR_WIDTH*NUM_WRITE_BUFFERS - 1 : 0] wpg_st_addr;
reg [MAIN_MEM_ADDR_WIDTH*NUM_WRITE_BUFFERS - 1 : 0] wpg_burst_length;
reg [NUM_WRITE_BUFFERS - 1 : 0] wpg_busy;
wire [NUM_WRITE_BUFFERS - 1 : 0] wpg_ack;

// read pattern generator signals
reg [MAIN_MEM_ADDR_WIDTH*NUM_READ_BUFFERS - 1 : 0] rpg_st_addr;
reg [MAIN_MEM_ADDR_WIDTH*NUM_READ_BUFFERS - 1 : 0] rpg_burst_length;
reg [NUM_READ_BUFFERS - 1 : 0] rpg_busy;
wire [NUM_READ_BUFFERS - 1 : 0] rpg_ack;
wire [NUM_READ_BUFFERS - 1 : 0] rpg_burst_ongoing;

// Writing port for writing buffers //
reg [NUM_WRITE_BUFFERS - 1 : 0] wr_buff_wren;
reg [MAIN_MEM_DATA_WIDTH*NUM_WRITE_BUFFERS - 1 : 0] wr_buff_wdata;
wire [NUM_WRITE_BUFFERS - 1 : 0] wr_buff_full;
wire [NUM_WRITE_BUFFERS - 1 : 0] wr_buff_empty;

// Reading port for reading buffers //
reg [NUM_READ_BUFFERS - 1 : 0] rd_buff_rden;
wire [MAIN_MEM_DATA_WIDTH*NUM_READ_BUFFERS - 1 : 0] rd_buff_rdata;
wire [NUM_READ_BUFFERS - 1 : 0] rd_buff_empty;
integer i;

always@(*) begin
  // host memory accessing assignments
  wpg_st_addr[HOST_WRITE_BUFFER_NUMBER*MAIN_MEM_ADDR_WIDTH +: MAIN_MEM_ADDR_WIDTH] = host_wpg_st_addr;
  wpg_burst_length[HOST_WRITE_BUFFER_NUMBER*MAIN_MEM_ADDR_WIDTH +: MAIN_MEM_ADDR_WIDTH] = host_wpg_burst_length;
  wpg_busy[HOST_WRITE_BUFFER_NUMBER] = host_wpg_busy;
  host_wpg_ack = wpg_ack[HOST_WRITE_BUFFER_NUMBER];
  wr_buff_wren[HOST_WRITE_BUFFER_NUMBER] = host_wr_buff_wren;
  wr_buff_wdata[HOST_WRITE_BUFFER_NUMBER*MAIN_MEM_DATA_WIDTH +: MAIN_MEM_DATA_WIDTH] = host_wr_buff_wdata;
  host_wr_buff_full = wr_buff_full[HOST_WRITE_BUFFER_NUMBER];

  rpg_st_addr[HOST_READ_BUFFER_NUMBER*MAIN_MEM_ADDR_WIDTH +: MAIN_MEM_ADDR_WIDTH] = host_rpg_st_addr;
  rpg_burst_length[HOST_READ_BUFFER_NUMBER*MAIN_MEM_ADDR_WIDTH +: MAIN_MEM_ADDR_WIDTH] = host_rpg_burst_length;
  rpg_busy[HOST_READ_BUFFER_NUMBER] = host_rpg_busy;
  host_rpg_ack = rpg_ack[HOST_READ_BUFFER_NUMBER];
  rd_buff_rden[HOST_READ_BUFFER_NUMBER] = host_rd_buff_rden;
  host_rd_buff_rdata = rd_buff_rdata[HOST_READ_BUFFER_NUMBER*MAIN_MEM_DATA_WIDTH +: MAIN_MEM_DATA_WIDTH];
  host_rd_buff_empty = rd_buff_empty[HOST_READ_BUFFER_NUMBER];

  // read pattern generator for reading frame for updating screen
  rpg_st_addr[SS_READ_BUFFER_NUMBER*MAIN_MEM_ADDR_WIDTH +: MAIN_MEM_ADDR_WIDTH] = ss_rpg_st_addr;
  rpg_burst_length[SS_READ_BUFFER_NUMBER*MAIN_MEM_ADDR_WIDTH +: MAIN_MEM_ADDR_WIDTH] = ss_rpg_burst_length;
  rpg_busy[SS_READ_BUFFER_NUMBER] = ss_rpg_busy;
  ss_rpg_ack = rpg_ack[SS_READ_BUFFER_NUMBER];
  ss_rd_buff_empty = rd_buff_empty[SS_READ_BUFFER_NUMBER]; 
  rd_buff_rden[SS_READ_BUFFER_NUMBER] = ss_rd_buff_rden;
  ss_rd_buff_rdata = rd_buff_rdata[SS_READ_BUFFER_NUMBER*MAIN_MEM_DATA_WIDTH +: MAIN_MEM_DATA_WIDTH];

  // drawing incremental circuit assignments
  rpg_st_addr[DRAW_READ_BUFFER_NUMBER*MAIN_MEM_ADDR_WIDTH +: MAIN_MEM_ADDR_WIDTH] = drw_inc_rpg_st_addr;
  rpg_burst_length[DRAW_READ_BUFFER_NUMBER*MAIN_MEM_ADDR_WIDTH +: MAIN_MEM_ADDR_WIDTH] = drw_inc_rpg_burst_length;
  rpg_busy[DRAW_READ_BUFFER_NUMBER] = drw_inc_rpg_busy;
  drw_inc_rpg_ack = rpg_ack[DRAW_READ_BUFFER_NUMBER];
  rd_buff_rden[DRAW_READ_BUFFER_NUMBER] = drw_inc_rd_buff_rden;
  drw_inc_rd_buff_rdata = rd_buff_rdata[DRAW_READ_BUFFER_NUMBER*MAIN_MEM_DATA_WIDTH +: MAIN_MEM_DATA_WIDTH];
  drw_inc_rd_buff_empty = rd_buff_empty[DRAW_READ_BUFFER_NUMBER];

  wpg_st_addr[DRAW_WRITE_BUFFER_NUMBER*MAIN_MEM_ADDR_WIDTH +: MAIN_MEM_ADDR_WIDTH] = drw_inc_wpg_st_addr;
  wpg_burst_length[DRAW_WRITE_BUFFER_NUMBER*MAIN_MEM_ADDR_WIDTH +: MAIN_MEM_ADDR_WIDTH] = drw_inc_wpg_burst_length;
  wpg_busy[DRAW_WRITE_BUFFER_NUMBER] = drw_inc_wpg_busy;
  drw_inc_wpg_ack = wpg_ack[DRAW_WRITE_BUFFER_NUMBER];
  wr_buff_wren[DRAW_WRITE_BUFFER_NUMBER] = drw_inc_wr_buff_wren;
  wr_buff_wdata[DRAW_WRITE_BUFFER_NUMBER*MAIN_MEM_DATA_WIDTH +: MAIN_MEM_DATA_WIDTH] = drw_inc_wr_buff_wdata;
  drw_inc_wr_buff_full = wr_buff_full[DRAW_WRITE_BUFFER_NUMBER];

	// wishbone slave to write read ports on memory system assignments
	wb_transaction_type = wb_slave_up_en ? wb_adr_i < UP_INSTR_BASE_ADDRESS : 1'b0;
	rpg_st_addr[WB_READ_BUFFER_NUMBER*MAIN_MEM_ADDR_WIDTH +: MAIN_MEM_ADDR_WIDTH] = wb_slave_rpg_st_addr;
  rpg_burst_length[WB_READ_BUFFER_NUMBER*MAIN_MEM_ADDR_WIDTH +: MAIN_MEM_ADDR_WIDTH] = wb_slave_rpg_burst_length;
  rpg_busy[WB_READ_BUFFER_NUMBER] = wb_slave_rpg_busy;
  wb_slave_rpg_ack = rpg_ack[WB_READ_BUFFER_NUMBER];
  rd_buff_rden[WB_READ_BUFFER_NUMBER] = wb_slave_rd_buff_rden;
  wb_slave_rd_buff_rdata = rd_buff_rdata[WB_READ_BUFFER_NUMBER*MAIN_MEM_DATA_WIDTH +: MAIN_MEM_DATA_WIDTH];
  wb_slave_rd_buff_empty = rd_buff_empty[WB_READ_BUFFER_NUMBER];

	wpg_st_addr[WB_WRITE_BUFFER_NUMBER*MAIN_MEM_ADDR_WIDTH +: MAIN_MEM_ADDR_WIDTH] = wb_slave_wpg_st_addr;
  wpg_burst_length[WB_WRITE_BUFFER_NUMBER*MAIN_MEM_ADDR_WIDTH +: MAIN_MEM_ADDR_WIDTH] = wb_slave_wpg_burst_length;
  wpg_busy[WB_WRITE_BUFFER_NUMBER] = wb_slave_wpg_busy;
  wb_slave_wpg_ack = wpg_ack[WB_WRITE_BUFFER_NUMBER];
  wr_buff_wren[WB_WRITE_BUFFER_NUMBER] = wb_slave_wr_buff_wren;
  wr_buff_wdata[WB_WRITE_BUFFER_NUMBER*MAIN_MEM_DATA_WIDTH +: MAIN_MEM_DATA_WIDTH] = wb_slave_wr_buff_wdata;
  wb_slave_wr_buff_full = wr_buff_full[WB_WRITE_BUFFER_NUMBER];

	wb_dat_o = wb_transaction_type ? wb_ctrl_wb_dat_o : wb_mem_sys_wb_dat_o;
	wb_ack_o = wb_transaction_type ? wb_ctrl_wb_ack_o : wb_mem_sys_wb_ack_o;

  // screen system assignments
  fetch_frame = ss_start || ss_start_cdec;
  frame_st_x = obj_st_x;
  frame_end_x = obj_st_x + obj_width - 1'b1;
  frame_width = obj_width;
  frame_st_y = obj_st_y;
  frame_end_y = obj_st_y + obj_height - 1'b1;
  frame_height = obj_height;
  frame_st_pix = obj_st_pix;

end

wb_slave_to_mem_sys_ports #(.DATA_WIDTH(WB_DATA_WIDTH), .ADDR_WIDTH(WB_ADDR_WIDTH), .MEM_DATA_WIDTH(MAIN_MEM_DATA_WIDTH)) wb_slave_to_mem_sys_ports_i (
  .up_en(wb_slave_up_en),
  .up_soft_reset(up_soft_reset),
  .wb_clk_i(clk), // System clock
  .wb_rst_i(!arst_n), // Synchronous reset (active high)
  
  // Wishbone interface
  .wb_adr_i(wb_adr_i), // Address input
  .wb_dat_i(wb_dat_i), // Data input
  .wb_dat_o(wb_mem_sys_wb_dat_o), // Data output
  .wb_we_i(wb_we_i),  // Write enable
  .wb_sel_i(wb_sel_i), // Byte select
  .wb_stb_i(wb_stb_i && !wb_transaction_type), // Strobe
  .wb_cyc_i(wb_cyc_i && !wb_transaction_type), // Cycle valid
  .wb_ack_o(wb_mem_sys_wb_ack_o), // Acknowledge
  
  // read pattern generator related signals
  .rpg_st_addr(wb_slave_rpg_st_addr),
  .rpg_burst_length(wb_slave_rpg_burst_length),
  .rpg_busy(wb_slave_rpg_busy),
  .rpg_ack(wb_slave_rpg_ack),
  // reading buffer related signals
  .rd_buff_rden(wb_slave_rd_buff_rden),
  .rd_buff_rdata(wb_slave_rd_buff_rdata),
  .rd_buff_empty(wb_slave_rd_buff_empty),
  
  // write pattern generator signals
  .wpg_st_addr(wb_slave_wpg_st_addr),
  .wpg_burst_length(wb_slave_wpg_burst_length),
  .wpg_busy(wb_slave_wpg_busy),
  .wpg_ack(wb_slave_wpg_ack),
  // Writing port for writing buffers //
  .wr_buff_wren(wb_slave_wr_buff_wren),
  .wr_buff_wdata(wb_slave_wr_buff_wdata),
  .wr_buff_full(wb_slave_wr_buff_full)
);

mem_sys mem_sys_inst (
  .mem_sys_clk(clk),
  .arst_n(arst_n),

  // Main memory signals
  // Reading port //
  .main_mem_rden(main_mem_rden),
  .main_mem_rd_addr(main_mem_rd_addr),
  .main_mem_rd_data(main_mem_rd_data),
  .main_mem_rd_data_valid(main_mem_rd_data_valid),

  // Writing port //
  .main_mem_wren(main_mem_wren),
  .main_mem_wr_addr(main_mem_wr_addr),
  .main_mem_wr_data(main_mem_wr_data),
  .main_mem_wr_data_ack(main_mem_wr_data_ack),

  // write pattern generator signals
  .wpg_st_addr(wpg_st_addr),
  .wpg_burst_length(wpg_burst_length),
  .wpg_busy(wpg_busy),
  .wpg_ack(wpg_ack),

  // read pattern generator signals
  .rpg_st_addr(rpg_st_addr),
  .rpg_burst_length(rpg_burst_length),
  .rpg_busy(rpg_busy),
  .rpg_ack(rpg_ack),
  .rpg_burst_ongoing(rpg_burst_ongoing),

  // Writing port for writing buffers //
  .wr_buff_wren(wr_buff_wren),
  .wr_buff_wdata(wr_buff_wdata),
  .wr_buff_full(wr_buff_full),
  .wr_buff_empty(wr_buff_empty),

  // Reading port for reading buffers //
  .rd_buff_rden(rd_buff_rden),
  .rd_buff_rdata(rd_buff_rdata),
  .rd_buff_empty(rd_buff_empty)
);

sram_controller #(MAIN_MEM_ADDR_WIDTH, MAIN_MEM_DATA_WIDTH) sram_controller_i (
  .clk(clk),
  .arst_n(arst_n),
  
  // Reading port
  .main_mem_rden(main_mem_rden),
  .main_mem_rd_addr(main_mem_rd_addr),
  .main_mem_rd_data(main_mem_rd_data),
  .main_mem_rd_data_valid(main_mem_rd_data_valid),
  
  // Writing port
  .main_mem_wren(main_mem_wren),
  .main_mem_wr_data_ack(main_mem_wr_data_ack),
  .main_mem_wr_addr(main_mem_wr_addr),
  .main_mem_wr_data(main_mem_wr_data),
  
  // SRAM interface
  .sram_addr(sram_addr),
  .sram_data(sram_data),
  .sram_ce_n(sram_ce_n),
  .sram_oe_n(sram_oe_n),
  .sram_we_n(sram_we_n)
);

screen_system screen_system_i (
  .clk(clk),
  .arst_n(arst_n),
  .ss_wren_reg(ss_wren_reg),
  .ss_wraddr_reg(ss_wraddr_reg),
  .ss_wrdata_reg(ss_wrdata_reg),
  .initialize(ss_initialize),
  .clock_divider(ss_clock_divider),
  // signals to color mapping
  .cm_wren(cm_wren),
  .cm_addr(cm_addr),
  .cm_data(cm_data),
  .ss_ld_sidebar(ss_ld_sidebar),
  // signals going to lacerta to fetch pixel values from memory system
  .rpg_st_addr(ss_rpg_st_addr),
  .rpg_burst_length(ss_rpg_burst_length),
  .rpg_busy(ss_rpg_busy),
  .rpg_ack(ss_rpg_ack),
  .rd_buff_rden(ss_rd_buff_rden),
  .rd_buff_rdata(ss_rd_buff_rdata),
  .rd_buff_empty(ss_rd_buff_empty),
  // signals coming from lacerta to update pixels
  .fetch_frame(fetch_frame),
  .frame_st_x(frame_st_x),
  .frame_end_x(frame_end_x),
  .frame_width(frame_width),
  .frame_st_y(frame_st_y),
  .frame_end_y(frame_end_y),
  .frame_height(frame_height),
  .frame_st_pix(frame_st_pix),
  .done(ss_done),
  .busy(ss_busy),
  // SPI ports
  .sck(sck),
  .ss(ss),
  .mosi(mosi),
  // data/command send to tft screen
  .dc(dc),
  .res(res),
  .blk(blk)
);

uart_ip_memory_mapped #(.NUM_BYTES_DATA(UART_BYTES_DATA), .NUM_BYTES_ADDRESS(UART_BYTES_ADDRESS) ) uart_ip_memory_mapped_i(
  .clk(clk),
  .arst_n(arst_n),
  // Memory related signals
  .mem_we(uart_mem_we),
  .mem_wdata(uart_mem_wdata),
  .mem_waddr(uart_mem_waddr),
  .mem_re(uart_mem_re),
  .mem_raddr(uart_mem_raddr),
  .mem_rdata(uart_mem_rdata),
  .mem_rdy(uart_mem_rdy),
  // UART related signals
  .rx(rx),
  .tx(tx)
);

wb_slave_memory_mapped #(.DATA_WIDTH(WB_DATA_WIDTH), .ADDR_WIDTH(WB_ADDR_WIDTH) ) wb_slave_memory_mapped_i (
  .wb_clk_i(clk), // System clock
  .wb_rst_i(!arst_n), // Synchronous reset (active high)
  .up_soft_reset(up_soft_reset),
  // Memory related signals
  .mem_we(wb_slave_mem_we),
  .mem_wdata(wb_slave_mem_wdata),
  .mem_wmask(wb_slave_mem_wmask),
  .mem_waddr(wb_slave_mem_waddr),
  .mem_wr_data_ack(wb_slave_mem_wr_data_ack),
  .mem_re(wb_slave_mem_re),
  .mem_raddr(wb_slave_mem_raddr),
  .mem_rdata(wb_slave_mem_rdata),
  .mem_rdy(wb_slave_mem_rdy),
  // Wishbone interface
  .wb_adr_i(wb_adr_i), // Address input
  .wb_dat_i(wb_dat_i), // Data input
  .wb_dat_o(wb_ctrl_wb_dat_o), // Data output
  .wb_we_i(wb_we_i),  // Write enable
  .wb_sel_i(wb_sel_i), // Byte select
  .wb_stb_i(wb_stb_i && wb_transaction_type), // Strobe
  .wb_cyc_i(wb_cyc_i && wb_transaction_type), // Cycle valid
  .wb_ack_o(wb_ctrl_wb_ack_o) // Acknowledge
);

command_arbiter_decoder command_arbiter_decoder_i(
	.clk(clk),
	.arst_n(arst_n),
	// write pattern generator and writing buffer signals (driven by commands coming from uart)
	.host_wpg_ack(host_wpg_ack),
	.host_wpg_st_addr(host_wpg_st_addr),
	.host_wpg_burst_length(host_wpg_burst_length),
	.host_wpg_busy(host_wpg_busy),
	.host_wr_buff_wren(host_wr_buff_wren),
	.host_wr_buff_wdata(host_wr_buff_wdata),
	.host_wr_buff_full(host_wr_buff_full),
	// read pattern generator and reading buffer signals (driven by commands coming from uart)
	.host_rpg_st_addr(host_rpg_st_addr),
	.host_rpg_burst_length(host_rpg_burst_length),
	.host_rpg_busy(host_rpg_busy),
	.host_rpg_ack(host_rpg_ack),
	.host_rd_buff_rden(host_rd_buff_rden),
	.host_rd_buff_rdata(host_rd_buff_rdata),
	.host_rd_buff_empty(host_rd_buff_empty),
  .obj_type(obj_type), // 0 - boolean, 1 vertical incremental, 2 horizontal incremental
  .obj_width(obj_width),
  .obj_height(obj_height),
  .obj_st_x(obj_st_x),
  .obj_st_y(obj_st_y),
  .obj_st_pix(obj_st_pix), // starting pixel
  .obj_st_mask(obj_st_mask),
  .obj_value(obj_value),
	.drw_inc_start(drw_inc_start),
	.drw_inc_busy(drw_inc_busy),
	.wb_slave_up_en(wb_slave_up_en),
	.up_soft_reset(up_soft_reset),
	.up_soft_reset_req(up_soft_reset_req),
  .ss_busy(ss_busy),
  .ss_start(ss_start_cdec),
  .ss_wren_reg(ss_wren_reg),
  .ss_wraddr_reg(ss_wraddr_reg),
  .ss_wrdata_reg(ss_wrdata_reg),
	.ss_clock_divider(ss_clock_divider),
  .ss_initialize(ss_initialize),
  .cm_wren(cm_wren),
  .cm_addr(cm_addr),
  .cm_data(cm_data),
  .ss_ld_sidebar(ss_ld_sidebar),
	// uart signals to control memory reading and writing port
	.uart_mem_we(uart_mem_we),
	.uart_mem_wdata(uart_mem_wdata),
	.uart_mem_waddr(uart_mem_waddr),
	.uart_mem_re(uart_mem_re),
	.uart_mem_raddr(uart_mem_raddr),
	.uart_mem_rdata(uart_mem_rdata),
	.uart_mem_rdy(uart_mem_rdy),
	// uart signals to control memory reading and writing port
	.wb_slave_mem_we(wb_slave_mem_we),
	.wb_slave_mem_wdata(wb_slave_mem_wdata),
	.wb_slave_mem_wmask(wb_slave_mem_wmask),
	.wb_slave_mem_waddr(wb_slave_mem_waddr),
	.wb_slave_mem_wr_data_ack(wb_slave_mem_wr_data_ack),
	.wb_slave_mem_re(wb_slave_mem_re),
	.wb_slave_mem_raddr(wb_slave_mem_raddr),
	.wb_slave_mem_rdata(wb_slave_mem_rdata),
	.wb_slave_mem_rdy(wb_slave_mem_rdy),
	.wb_mem_sys_wb_ack_o(wb_mem_sys_wb_ack_o)
);
	
mask_generator mask_generator_i(
  .clk(clk),
  .arst_n(arst_n),
  .start(drw_inc_start),
  .obj_type(obj_type), // 0 - boolean, 1 vertical incremental, 2 horizontal incremental
  .obj_width(obj_width),
  .obj_height(obj_height),
  .obj_st_pix(obj_st_pix), // starting pixel
  .obj_st_mask(obj_st_mask),
  .obj_value(obj_value),
  .rpg_st_addr(drw_inc_rpg_st_addr),
  .rpg_burst_length(drw_inc_rpg_burst_length),
  .rpg_busy(drw_inc_rpg_busy),
  .rpg_ack(drw_inc_rpg_ack),
  .rd_buff_rden(drw_inc_rd_buff_rden),
  .rd_buff_rdata(drw_inc_rd_buff_rdata),
  .rd_buff_empty(drw_inc_rd_buff_empty),
  .wpg_st_addr(drw_inc_wpg_st_addr),
  .wpg_burst_length(drw_inc_wpg_burst_length),
  .wpg_busy(drw_inc_wpg_busy),
  .wpg_ack(drw_inc_wpg_ack),
  .wr_buff_wren(drw_inc_wr_buff_wren),
  .wr_buff_wdata(drw_inc_wr_buff_wdata),
  .wr_buff_full(drw_inc_wr_buff_full),
  .ss_busy(ss_busy),
  .ss_start(ss_start),
  .busy(drw_inc_busy),
  .done(drw_inc_done)
);

endmodule
