///////////////////////////////////////////////////////////////////////////////////////
// Company: Mifral
// Engineer: Miguel Rivera
// 
// Design Name: lacerta
// Module Name: tft_control_fsm
//
// Description:
// this module is responsible of generating all streaming commands and data
// sent to the tft screen through the spi_master module, this contains
// a configuration memory that is written by the command_arbiter_decoder
// during the initialization, this access the color map table, and the main
// memory to fetch data to be sent to the tft screen, when updating the active
// visible are of the gui (where indicators objects are), we read 1 memory
// word (1 Byte) per pixel that encodes the pixel address for color map table,
// and when updating the sidebar with logos, we read 2 memory words (2 Bytes)
// per pixel
///////////////////////////////////////////////////////////////////////////////////////

module tft_control_fsm (
	output wire oinitialization_done,
	output wire [3:0] ostate,


  input wire clk,
  input wire arst_n,
  input wire initialize, // this will be set when the tft screen initialization process should begin
  // SPI master control ports
  output reg tnsm,
  output reg [7 : 0] tnsm_data,
  input wire tnsm_busy,
  input wire tnsm_ack,
  input wire tnsm_done,
  // signals going to lacerta to fetch pixel values from memory system
  output reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] rpg_st_addr,
  output reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] rpg_burst_length,
  output reg rpg_busy,
  input wire rpg_ack,
  output reg rd_buff_rden,
  input wire [MAIN_MEM_DATA_WIDTH - 1 : 0] rd_buff_rdata,
  input wire rd_buff_empty,
  // signals to color mapping
  output reg [$clog2(COLOR_MAP_NUM) - 1 : 0] color_sel,
  input wire [15 : 0] color,
  // signals coming from lacerta to write into the initialization memory,
  input wire ss_wren_reg,
  input wire [$clog2(SCREEN_INIT_MEM_SIZE) - 1 : 0] ss_wraddr_reg,
  input wire [9 : 0] ss_wrdata_reg,
  // signals coming from lacerta to update pixels
  input wire fetch_frame,
  input wire [9 : 0] frame_st_x,
  input wire [9 : 0] frame_end_x,
  input wire [MAXIMUM_INCREMENTAL_WIDTH_BITS - 1 : 0] frame_width,
  input wire [9 : 0] frame_st_y,
  input wire [9 : 0] frame_end_y,
  input wire [MAXIMUM_INCREMENTAL_HEIGHT_BITS - 1 : 0] frame_height,
  input wire [MAIN_MEM_ADDR_WIDTH - 1 : 0] frame_st_pix,
  input wire ss_ld_sidebar,
  output reg done,
  output reg busy,
  // data/command send to tft screen
  output reg dc,
  output reg res,
  output wire blk
);

assign ostate = curr_state;
assign oinitialization_done = initialization_done;
assign blk = 1'b1;

localparam CLK_CYCLES_PER_MS = CLOCK_FREQUENCY/1_000; // 1 ms == 1 s / 1_000
localparam X_MAX = SCREEN_WIDTH - 1; // maximum coordinate for x
localparam Y_MAX = SCREEN_HEIGHT - 1; // maximum coordinate for y


reg [$clog2(CLK_CYCLES_PER_MS) - 1 : 0] ms_cnt;
reg ms_tick; // 1 ms tick

always@(posedge clk, negedge arst_n) begin
  if(!arst_n) begin
    ms_cnt <= {$clog2(CLK_CYCLES_PER_MS){1'b0}};
    ms_tick <= 1'b0;
  end else begin
    ms_tick <= 1'b0; // we want this to be a pulse
    if(ms_cnt == (CLK_CYCLES_PER_MS - 1)) begin
      ms_tick <= 1'b1;
      ms_cnt <= {$clog2(CLK_CYCLES_PER_MS){1'b0}};
    end else begin
      ms_cnt <= ms_cnt + 1'b1;
    end
  end
end

// using a maximum delay time of 255 ms
reg [7:0] sfty_dly_cnt; // This holds the actual number of miliseconds
reg [7:0] sfty_dly_req; // This holds the number of miliseconds that the delaying logic is to wait until sfty_dly_done flag is asserted
reg sfty_dly_start;
reg sfty_dly_busy;
reg sfty_dly_done;

always@(posedge clk, negedge arst_n) begin
  if(!arst_n) begin
    sfty_dly_cnt <= 8'd0;
    sfty_dly_busy <= 1'b0;
    sfty_dly_done <= 1'b0;
  end else begin
    sfty_dly_done <= 1'b0; // we want this to be a single pulse
    if(sfty_dly_start && (!sfty_dly_busy)) begin
      sfty_dly_busy <= 1'b1;
      sfty_dly_cnt <= sfty_dly_req;
    end else if(sfty_dly_busy) begin
      if(ms_tick) begin
        if(sfty_dly_cnt == 0) begin // I decided to compare with 0, an extra ms in delay is safer, as ms_cnt is running freely, and thus, the first ms_tick might not be a complete 1ms delay
          sfty_dly_busy <= 1'b0;
          sfty_dly_done <= 1'b1;
        end else begin
          sfty_dly_cnt <= sfty_dly_cnt - 1'b1;
        end
      end
    end
  end
end

reg [9 : 0] init_mem [SCREEN_INIT_MEM_SIZE];
reg [$clog2(SCREEN_INIT_MEM_SIZE) - 1 : 0] init_rom_raddr;
wire [9 : 0] init_rom_rdata;

integer i; // TODO: need to fix this for synthesis

always@(posedge clk, negedge arst_n) begin
  if(!arst_n) begin
    for(i = 0; i < SCREEN_INIT_MEM_SIZE; i = i + 1) begin
      init_mem[i] <= 10'd0; // should we initialize to a default configuration?
    end
  end else begin
    if(ss_wren_reg) begin
      init_mem[ss_wraddr_reg] <= ss_wrdata_reg;
    end
  end
end

assign init_rom_rdata = init_mem[init_rom_raddr];

parameter STATE_IDLE                  = 4'b0000;
parameter STATE_INITIALIZE            = 4'b0001;
parameter STATE_WAIT_DELAY            = 4'b0010;
parameter STATE_WAIT_SPI              = 4'b0011;
parameter STATE_INITIALIZE_DONE_IDLE  = 4'b0100;
parameter STATE_SET_CASET_FRAME       = 4'b0101;
parameter STATE_SET_RASET_FRAME       = 4'b0110;
parameter STATE_WAIT_SPI_CA_RA_SET    = 4'b0111;
parameter STATE_START_PG              = 4'b1000;
parameter STATE_WAIT_PG               = 4'b1001;
parameter STATE_RD_DATA               = 4'b1010;
parameter STATE_SEND_PIX_DATA         = 4'b1011;
parameter STATE_WAIT_SPI_PIX_DATA     = 4'b1100;
parameter STATE_SEND_RAMWR            = 4'b1101;
parameter STATE_WAIT_SPI_PIX_RAMWR    = 4'b1110;
parameter STATE_READ_COLOR_MAP        = 4'b1111;

reg [3 : 0] curr_state;
reg initialization_done;
reg [8 + 8 * 4 - 1 : 0] caset_data; // this will hold the 40 bits that are to be sent to tft screen to start a CASET command
reg [8 + 8 * 4 - 1 : 0] raset_data; // this will hold the 40 bits that are to be sent to tft screen to start a RASET command
reg [2 : 0] caset_raset_cnt; // counts the number of bytes sent for the CASET/RASET commands
reg caset_raset_sel; // this will be 0 if caset is being send to the tft screen, 1 if raset is being send
reg [MAXIMUM_INCREMENTAL_HEIGHT_BITS - 1 : 0] row_cnt;
reg [MAXIMUM_INCREMENTAL_WIDTH_BITS - 1 : 0] col_cnt;
reg pix_byte_sel; // whether we are issuing pixel low byte (0) or high byte (1)
wire [1 : 0] rom_type;
wire [7 : 0] rom_data;
reg [15 : 0] pixel_data;

wire [15 : 0] frame_st_x_ext;
wire [15 : 0] frame_end_x_ext;
wire [15 : 0] frame_st_y_ext;
wire [15 : 0] frame_end_y_ext;

reg sidebar_ongoing;
reg [7 : 0] sidebar_data_byte;
wire [15 : 0] sidebar_st_x;
wire [15 : 0] sidebar_end_x;
wire [15 : 0] sidebar_st_y;
wire [15 : 0] sidebar_end_y;

assign frame_st_x_ext = {6'd0, frame_st_x}; // extending to 16 bits as required by tft screen
assign frame_end_x_ext = {6'd0, frame_end_x}; // extending to 16 bits as required by tft screen
assign frame_st_y_ext =  {6'd0, frame_st_y}; // extending to 16 bits as required by tft screen
assign frame_end_y_ext = {6'd0, frame_end_y}; // extending to 16 bits as required by tft screen
assign sidebar_st_x = ACTIVE_SCREEN_WIDTH;
assign sidebar_end_x = SCREEN_WIDTH;
assign sidebar_st_y = 0;
assign sidebar_end_y = SCREEN_HEIGHT;

assign {rom_type, rom_data} = init_rom_rdata;

always@(posedge clk, negedge arst_n) begin
  if(!arst_n) begin
    curr_state <= STATE_IDLE;
    dc <= 1'b0;
    init_rom_raddr <= {$clog2(SCREEN_INIT_MEM_SIZE){1'b0}};
    initialization_done <= 1'b0;
    tnsm <= 1'b0;
    tnsm_data <= 8'd0;
    sfty_dly_req <= 8'd0;
    sfty_dly_start <= 1'b0;
    caset_data <= 40'd0;
    raset_data <= 40'd0;
    caset_raset_cnt <= 3'd0;
    caset_raset_sel <= 1'b0;
    row_cnt <= {MAXIMUM_INCREMENTAL_HEIGHT_BITS{1'b0}};
    col_cnt <= {MAXIMUM_INCREMENTAL_WIDTH_BITS{1'b0}};
    rpg_st_addr <= {MAIN_MEM_ADDR_WIDTH{1'b0}};
    rpg_burst_length <= {MAIN_MEM_ADDR_WIDTH{1'b0}};
    rpg_busy <= 1'b0;
    rd_buff_rden <= 1'b0;
    done <= 1'b0;
    busy <= 1'b0;
    res <= 1'b0;
    pix_byte_sel <= 1'b0;
    color_sel <= {$clog2(COLOR_MAP_NUM){1'b0}};
    pixel_data <= 16'd0;
    sidebar_ongoing <= 1'b0;
    sidebar_data_byte <= 8'd0;
  end else begin
    sfty_dly_start <= 1'b0; // we want this to be a pulse
    done <= 1'b0;

	 if(tnsm_ack)
			tnsm <= 1'b0;

	 if(rpg_ack)
		rpg_busy <= 1'b0;

    case(curr_state)

      STATE_IDLE: begin
        init_rom_raddr <= {$clog2(SCREEN_INIT_MEM_SIZE){1'b0}};
        if(initialize) begin
          res <= 1'b0; // reset the tft screen
          curr_state <= STATE_INITIALIZE;
        end
      end

      STATE_INITIALIZE: begin
        if(init_rom_raddr == (SCREEN_INIT_MEM_SIZE - 1)) begin // we issue all commands, we have to make sure to fill all unused addresses with zeros (NOPs)
          initialization_done <= 1'b1;
          curr_state <= STATE_INITIALIZE_DONE_IDLE;
        end else begin
          case(rom_type) // decode the initialization ram item type

            2'b00: begin // COMMAND type
              dc <= 1'b0; // command is 0
              tnsm <= 1'b1;
              tnsm_data <= rom_data;
              curr_state <= STATE_WAIT_SPI;
            end

            2'b01: begin // DATA type
              dc <= 1'b1; // data is 1
              tnsm <= 1'b1;
              tnsm_data <= rom_data;
              curr_state <= STATE_WAIT_SPI;
            end

            2'b10: begin // DELAY type
              dc <= 1'b0; // don't care, as we are not transmitting through spi
              sfty_dly_req <= rom_data;
              sfty_dly_start <= 1'b1;
              tnsm_data <= rom_data;
              curr_state <= STATE_WAIT_DELAY;
            end

            default: begin // this should never happen
              curr_state <= STATE_IDLE;
            end
          endcase
        end
      end

      STATE_WAIT_DELAY: begin
        if(sfty_dly_done) begin
          res <= 1'b1; // after first 20ms delay during initialization, we release the reset for tft screen
          init_rom_raddr <= init_rom_raddr + 1'b1;
          curr_state <= STATE_INITIALIZE;
        end
      end

      STATE_WAIT_SPI: begin
        if(tnsm_done) begin
          if(initialization_done) begin
            curr_state <= STATE_INITIALIZE_DONE_IDLE;
          end else begin
            init_rom_raddr <= init_rom_raddr + 1'b1;
            curr_state <= STATE_INITIALIZE;
          end
        end
      end

      STATE_INITIALIZE_DONE_IDLE: begin // this state will be used to detect when initialization is done, and thus, pixels can be written into the tft screen ram
        if(ss_ld_sidebar) begin
          sidebar_ongoing <= 1'b1;
          busy <= 1'b1;
          caset_data <= {8'h2A, // hard-coding 8'h2A for CASET, as most controllers use this as standard
                        sidebar_st_x[15:8],
                        sidebar_st_x[7:0],
                        sidebar_end_x[15:8],
                        sidebar_end_x[7:0]};
          raset_data <= {8'h2B, // hard-coding 8'h2B for RASET, as most controllers use this as standard
                        sidebar_st_y[15:8],
                        sidebar_st_y[7:0],
                        sidebar_end_y[15:8],
                        sidebar_end_y[7:0]}; // concatenate RASET command, RASET data, and RAMWR command
          caset_raset_cnt <= 3'd0;
          caset_raset_sel <= 1'b0;
          curr_state <= STATE_SET_CASET_FRAME;
        end else if(fetch_frame) begin // a new frame window was requested to be written into screen
          busy <= 1'b1;
          caset_data <= {8'h2A, // hard-coding 8'h2A for CASET, as most controllers use this as standard
                        frame_st_x_ext[15:8],
                        frame_st_x_ext[7:0],
                        frame_end_x_ext[15:8],
                        frame_end_x_ext[7:0]};
          raset_data <= {8'h2B, // hard-coding 8'h2B for RASET, as most controllers use this as standard
                        frame_st_y_ext[15:8],
                        frame_st_y_ext[7:0],
                        frame_end_y_ext[15:8],
                        frame_end_y_ext[7:0]}; // concatenate RASET command, RASET data, and RAMWR command
          caset_raset_cnt <= 3'd0;
          caset_raset_sel <= 1'b0;
          curr_state <= STATE_SET_CASET_FRAME;
        end
      end

      STATE_SET_CASET_FRAME: begin
        if(caset_raset_cnt == 5) begin // CASET frame is 1 command byte, 2 start x data bytes. and 2 end x data bytes
          caset_raset_sel <= 1'b1;
          caset_raset_cnt <= 3'd0;
          curr_state <= STATE_SET_RASET_FRAME;
        end else begin
          if(caset_raset_cnt == 3'd0)
            dc <= 1'b0; // command is 0
          else
            dc <= 1'b1; // data is 1
          tnsm <= 1'b1;
          tnsm_data <= caset_data[8 + 8 * 4 - 1 : 8 * 4]; // we send highest byte first
          caset_data <= {caset_data[8 * 4 - 1 : 0], 8'd0}; // we shift 8 bits to the left
          curr_state <= STATE_WAIT_SPI_CA_RA_SET;
        end
      end

      STATE_SET_RASET_FRAME: begin
        if(caset_raset_cnt == 5) begin // RASET frame is 1 command byte, 2 start y data bytes. and 2 end y data bytes, and the extra RAMWR command
          caset_raset_sel <= 1'b0;
          caset_raset_cnt <= 3'd0;
          curr_state <= STATE_SEND_RAMWR;
        end else begin
          if(caset_raset_cnt == 3'd0)
            dc <= 1'b0; // command is 0
          else
            dc <= 1'b1; // data is 1
          tnsm <= 1'b1;
          tnsm_data <= raset_data[8 + 8 * 4 - 1 : 8 * 4]; // we send highest byte first
          raset_data <= {raset_data[8 * 4 - 1 : 0], 8'd0}; // we shift 8 bits to the left
          curr_state <= STATE_WAIT_SPI_CA_RA_SET;
        end
      end

      STATE_SEND_RAMWR: begin
        dc <= 1'b0;
        tnsm <= 1'b1;
        tnsm_data <= 8'h2C; // send RAMWR - hard-coding 8'h2C for RAMWR, as most controllers use this as standard
        curr_state <= STATE_WAIT_SPI_PIX_RAMWR;
      end

      STATE_WAIT_SPI_PIX_RAMWR: begin
        if(tnsm_done) begin
          row_cnt <= {MAXIMUM_INCREMENTAL_HEIGHT_BITS{1'b0}};
          col_cnt <= {MAXIMUM_INCREMENTAL_WIDTH_BITS{1'b0}};
          if(sidebar_ongoing) begin // we will send all pixels of sidebar
            rpg_st_addr <= SIDEBAR_STADDR;
            rpg_burst_length <= SIDEBAR_WIDTH*2; // 2 bytes/words per pixel
          end else begin
            rpg_st_addr <= frame_st_pix;
            rpg_burst_length <= frame_width;
          end
          curr_state <= STATE_START_PG;
        end
      end

      STATE_WAIT_SPI_CA_RA_SET: begin
        if(tnsm_done) begin
          caset_raset_cnt <= caset_raset_cnt + 1'b1;
          if(caset_raset_sel) begin
            curr_state <= STATE_SET_RASET_FRAME;
          end else begin
            curr_state <= STATE_SET_CASET_FRAME;
          end
        end
      end

      STATE_START_PG: begin
        if(sidebar_ongoing ? row_cnt < SIDEBAR_HEIGHT : row_cnt < frame_height) begin
          rpg_busy <= 1'b1;
          curr_state <= STATE_WAIT_PG;
        end else begin
          sidebar_ongoing <= 1'b0;
          busy <= 1'b0;
          done <= 1'b1;
          curr_state <= STATE_INITIALIZE_DONE_IDLE;
        end
      end

      STATE_WAIT_PG: begin
        if(sidebar_ongoing)
          rpg_st_addr <= rpg_st_addr + (SIDEBAR_WIDTH*2); // we are using 16 bit colors, so we have 2 byte per pixel
        else
          rpg_st_addr <= rpg_st_addr + ACTIVE_SCREEN_WIDTH; // we are using color mapping, so we have 1 byte per pixel
        curr_state <= STATE_RD_DATA;
      end

      STATE_RD_DATA: begin
			  if(!rd_buff_empty) begin
          color_sel <= rd_buff_rdata[MAIN_MEM_DATA_WIDTH - 1] ?  rd_buff_rdata[MAIN_MEM_DATA_WIDTH - 2 : MAIN_MEM_DATA_WIDTH - 1 - $clog2(COLOR_MAP_NUM)] : rd_buff_rdata[$clog2(COLOR_MAP_NUM) - 2 : 0]; // for MAIN_MEM_DATA_WIDTH = 8 .. rd_buff_rdata[7] ? rd_buff_rdata[6:3] : rd_buff_rdata[2:0]
          rd_buff_rden <= 1'b1; // read the first pixel of a row
          sidebar_data_byte <= rd_buff_rdata;
          curr_state <= STATE_READ_COLOR_MAP;
		    end
      end

      STATE_READ_COLOR_MAP: begin
			  rd_buff_rden <= 1'b0;
        pixel_data <= color;
        pix_byte_sel <= ~pix_byte_sel;
        if(pix_byte_sel)
          col_cnt <= col_cnt + 1'b1;
        dc <= 1'b1; // data is 1
        tnsm <= 1'b1;
        if(sidebar_ongoing)
          tnsm_data <= sidebar_data_byte; // we send pixel data byte gotten from memory system
        else
          tnsm_data <= pix_byte_sel ? pixel_data[7 : 0] : color[15 : 8]; // we send pixel data gotten from color mapping - high byte first
        curr_state <= STATE_WAIT_SPI_PIX_DATA;
      end

      STATE_WAIT_SPI_PIX_DATA: begin
        if(tnsm_done) begin
          if(sidebar_ongoing ? col_cnt == SIDEBAR_WIDTH : col_cnt == frame_width) begin // a whole row was sent to tft screen - frame_width if regular frame, or SIDEBAR_WIDTH if sidebar ongoing
            row_cnt <= row_cnt + 1'b1;
            col_cnt <= {MAXIMUM_INCREMENTAL_WIDTH_BITS{1'b0}};
            curr_state <= STATE_START_PG;
          end else begin
            if((!pix_byte_sel) || sidebar_ongoing)
              curr_state <= STATE_RD_DATA;
            else
              curr_state <= STATE_READ_COLOR_MAP;
          end
        end
      end

    endcase

  end
end

endmodule
