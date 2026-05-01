module dig_top(
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

  // VGA interface
  output wire [7:0] vga_ored,
  output wire [7:0] vga_ogreen,
  output wire [7:0] vga_oblue,
  output wire vga_hsync,
  output wire vga_vsync,
  output wire vga_sync,
  output wire vga_blank,
  output wire vga_clk
);

localparam VGA_READ_BUFFER_NUMBER = 0;
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
// ======================================== vga controller signals ======================================= //
// ======================================================================================================= //
reg vctrl_enable;
reg vga_mask;
reg [VGA_RED_WIDTH - 1 : 0] vga_ired;
reg [VGA_GREEN_WIDTH - 1 : 0] vga_igreen;
reg [VGA_BLUE_WIDTH - 1 : 0] vga_iblue;
reg vctrl_buffer_empty;
wire vctrl_buffer_rden;
wire [UART_BYTES_DATA * 8 - 1 : 0] conf_logics_0;
wire [UART_BYTES_DATA * 8 - 1 : 0] conf_logics_1;

// ======================================================================================================= //
// ===================================== drawing incremental signals ===================================== //
// ======================================================================================================= //
wire drw_inc_start;
wire [3:0] obj_type; // 0 - boolean, 1 vertical incremental, 2 horizontal incremental
wire [10:0] obj_width;
wire [10:0] obj_height;
wire [21:0] obj_st_pix; // starting pixel
wire [21:0] obj_st_mask;
wire [14:0] obj_value;
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

// accumulation raw dependencies
reg [NUM_READ_BUFFERS - 1 : 0] rpg_pre_stall;
reg [NUM_READ_BUFFERS - 1 : 0] rpg_stall;

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

  // read pattern generator for reading frame for streaming through vga
  rpg_st_addr[VGA_READ_BUFFER_NUMBER*MAIN_MEM_ADDR_WIDTH +: MAIN_MEM_ADDR_WIDTH] = {MAIN_MEM_ADDR_WIDTH{1'b0}};
  rpg_burst_length[VGA_READ_BUFFER_NUMBER*MAIN_MEM_ADDR_WIDTH +: MAIN_MEM_ADDR_WIDTH] = FRAME_SIZE[MAIN_MEM_ADDR_WIDTH - 1 : 0];
  rpg_busy[VGA_READ_BUFFER_NUMBER] = 1'b1;
  // rpg_ack[1]; // TODO: this is not necessary
  vctrl_buffer_empty = rd_buff_empty[VGA_READ_BUFFER_NUMBER]; // reading buffer for vga controller is index 1
  rd_buff_rden[VGA_READ_BUFFER_NUMBER] = vctrl_buffer_rden; // reading buffer for vga controller is index 1
  {vga_mask, vga_ired} = rd_buff_rdata[VGA_READ_BUFFER_NUMBER*MAIN_MEM_DATA_WIDTH +: MAIN_MEM_DATA_WIDTH]; // reading buffer for vga controller is index 1
	vga_igreen = vga_mask ? {VGA_GREEN_WIDTH{1'b1}} : vga_ired;
	vga_iblue = vga_mask ? {VGA_BLUE_WIDTH{1'b1}} : vga_ired;
	vga_ired = vga_mask ? {VGA_RED_WIDTH{1'b1}} : vga_ired;
  //{vga_mask, vga_ired, vga_igreen, vga_iblue} = rd_buff_rdata[1]; // reading buffer for vga controller is index 1
  vctrl_enable = 1'b1;

  for(i = 0; i < NUM_READ_BUFFERS; i = i + 1) begin
    rpg_pre_stall[i] = 1'b0; // TODO: unused
    rpg_stall[i] = 1'b0; // TODO: unused
  end

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
	wb_transaction_type = (wb_adr_i & 32'hF000_0000) == MMIO_MEM_OFFSET ? 1'b1 : (wb_adr_i & 32'hF000_0000) == UP_RESET_VECTOR ? 1'b0 : 1'b0;
	rpg_st_addr[WB_READ_BUFFER_NUMBER*MAIN_MEM_ADDR_WIDTH +: MAIN_MEM_ADDR_WIDTH] = wb_slave_rpg_st_addr + UP_INSTR_OFFSET;
  rpg_burst_length[WB_READ_BUFFER_NUMBER*MAIN_MEM_ADDR_WIDTH +: MAIN_MEM_ADDR_WIDTH] = wb_slave_rpg_burst_length;
  rpg_busy[WB_READ_BUFFER_NUMBER] = wb_slave_rpg_busy;
  wb_slave_rpg_ack = rpg_ack[WB_READ_BUFFER_NUMBER];
  rd_buff_rden[WB_READ_BUFFER_NUMBER] = wb_slave_rd_buff_rden;
  wb_slave_rd_buff_rdata = rd_buff_rdata[WB_READ_BUFFER_NUMBER*MAIN_MEM_DATA_WIDTH +: MAIN_MEM_DATA_WIDTH];
  wb_slave_rd_buff_empty = rd_buff_empty[WB_READ_BUFFER_NUMBER];

	wpg_st_addr[WB_WRITE_BUFFER_NUMBER*MAIN_MEM_ADDR_WIDTH +: MAIN_MEM_ADDR_WIDTH] = wb_slave_wpg_st_addr + UP_INSTR_OFFSET;
  wpg_burst_length[WB_WRITE_BUFFER_NUMBER*MAIN_MEM_ADDR_WIDTH +: MAIN_MEM_ADDR_WIDTH] = wb_slave_wpg_burst_length;
  wpg_busy[WB_WRITE_BUFFER_NUMBER] = wb_slave_wpg_busy;
  wb_slave_wpg_ack = wpg_ack[WB_WRITE_BUFFER_NUMBER];
  wr_buff_wren[WB_WRITE_BUFFER_NUMBER] = wb_slave_wr_buff_wren;
  wr_buff_wdata[WB_WRITE_BUFFER_NUMBER*MAIN_MEM_DATA_WIDTH +: MAIN_MEM_DATA_WIDTH] = wb_slave_wr_buff_wdata;
  wb_slave_wr_buff_full = wr_buff_full[WB_WRITE_BUFFER_NUMBER];

	wb_dat_o = wb_transaction_type ? wb_ctrl_wb_dat_o : wb_mem_sys_wb_dat_o;
	wb_ack_o = wb_transaction_type ? wb_ctrl_wb_ack_o : wb_mem_sys_wb_ack_o;

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

mem_sys mem_sys_i (
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

  // accumulation raw dependencies
  .rpg_pre_stall(rpg_pre_stall),
  .rpg_stall(rpg_stall),

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

ram ram_i(
  .clk(clk),
  // Reading port //
  .main_mem_rden(main_mem_rden),
  .main_mem_rd_addr(main_mem_rd_addr),
  .main_mem_rd_data(main_mem_rd_data),
  .main_mem_rd_data_valid(main_mem_rd_data_valid),
  
  // Writing port //
  .main_mem_wren(main_mem_wren),
  .main_mem_wr_addr(main_mem_wr_addr),
  .main_mem_wr_data(main_mem_wr_data),
  .main_mem_wr_data_ack(main_mem_wr_data_ack)
);

vga_controller vga_controller_i(
	.clk(clk),
	.arst_n(arst_n),
	.enable(vctrl_enable),
	.red({vga_ired,3'b000}),
	.green({vga_igreen,3'b000}),
	.blue({vga_iblue,3'b000}),
	.empty(vctrl_buffer_empty),
	.rden(vctrl_buffer_rden),
  // configuration logicisters
  .hsync_act(conf_logics_0[10:0]),
  .hsync_deact(conf_logics_0[20:11]),
  .vsync_act(conf_logics_1[10:0]),
  .vsync_deact(conf_logics_1[20:11]),
	// VGA signals
	.ored(vga_ored),
	.ogreen(vga_ogreen),
	.oblue(vga_oblue),
	.h_sync(vga_hsync),
	.v_sync(vga_vsync),
	.sync(vga_sync),
	.blank(vga_blank),
	.oclk(vga_clk)
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
	.conf_logics_0(conf_logics_0),
	.conf_logics_1(conf_logics_1),
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
  .obj_st_pix(obj_st_pix), // starting pixel
  .obj_st_mask(obj_st_mask),
  .obj_value(obj_value),
	.drw_inc_start(drw_inc_start),
	.drw_inc_busy(drw_inc_busy),
	.wb_slave_up_en(wb_slave_up_en),
	.up_soft_reset(up_soft_reset),
	.up_soft_reset_req(up_soft_reset_req),
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
  .busy(drw_inc_busy),
  .done(drw_inc_done)
);

endmodule
