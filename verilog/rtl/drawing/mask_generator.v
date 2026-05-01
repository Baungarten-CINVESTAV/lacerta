////////////////////////////////////////////////////////////////////////////////////
// Company: Mifral
// Engineer: Miguel Rivera
// 
// Design Name: lacerta
// Module Name: mask_generator
//
// Description:
// this module generates and update the mask bits on the main memory, based on
// commands and data coming from the command_arbiter_decoder, this will block will
// trigger on object command update reception, then update all the mask bits
// for the specified object in the command, then, it will indicate to the
// screen system to update the relevant pixels in the tft screen
///////////////////////////////////////////////////////////////////////////////////

module mask_generator(
  input wire clk,
  input wire arst_n,
  input wire start,
  input wire [3 : 0] obj_type, // 0 - boolean, 1 vertical incremental, 2 horizontal incremental
  input wire [MAXIMUM_INCREMENTAL_WIDTH_BITS - 1 : 0] obj_width,
  input wire [MAXIMUM_INCREMENTAL_HEIGHT_BITS - 1 : 0] obj_height,
  input wire [MAIN_MEM_ADDR_WIDTH - 1 : 0] obj_st_pix, // starting pixel
  input wire [MAIN_MEM_ADDR_WIDTH - 1 : 0] obj_st_mask,
  input wire [9 : 0] obj_value,
  output reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] rpg_st_addr,
  output reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] rpg_burst_length,
  output reg rpg_busy,
  input wire rpg_ack,
  output reg rd_buff_rden,
  input wire [MAIN_MEM_DATA_WIDTH - 1 : 0] rd_buff_rdata,
  input wire rd_buff_empty,
  output reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] wpg_st_addr,
  output reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] wpg_burst_length,
  output reg wpg_busy,
  input wire wpg_ack,
  output reg wr_buff_wren,
  output reg [MAIN_MEM_DATA_WIDTH - 1 : 0] wr_buff_wdata,
  input wire wr_buff_full,
  input wire ss_busy,
  output reg ss_start,
  output reg busy,
  output reg done
);

// states for drawing circuit state machine
localparam STATE_IDLE          = 4'b0000;
localparam STATE_START         = 4'b0001;
localparam STATE_START_PG      = 4'b0010;
localparam STATE_WAIT_PG       = 4'b0011;
localparam STATE_RD_DATA       = 4'b0100;
localparam STATE_WR_DATA       = 4'b0101;
localparam STATE_TMP           = 4'b0110;
localparam STATE_RD_MASK       = 4'b0111;
localparam STATE_RD_MASK2      = 4'b1000;
localparam STATE_START_PG_MASK = 4'b1001;
localparam STATE_WAIT_SS_DONE  = 4'b1010;

reg [3 : 0] curr_state;
reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] obj_addr;
reg [MAIN_MEM_DATA_WIDTH - 1 : 0] rdata;
reg [MAXIMUM_INCREMENTAL_HEIGHT_BITS - 1 : 0] row_cnt;
reg [MAXIMUM_INCREMENTAL_WIDTH_BITS - 1 : 0] col_cnt;
reg [MAXIMUM_INCREMENTAL_WIDTH - 1 : 0] mask;
reg [MAXIMUM_INCREMENTAL_WIDTH_BITS - 1 : 0] mask_cnt;
reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] mask_addr;
reg hor_incr_type; // 1 if horizontal incremental object type
reg ver_incr_type; // 1 if vertical incremental object type
reg graph_type; // 1 if graph object type
reg mask_type; // 1 if mask object type like 7 segment display

always@(posedge clk, negedge arst_n) begin
  if(!arst_n) begin
    rpg_st_addr <= {MAIN_MEM_ADDR_WIDTH{1'b0}};
    rpg_burst_length <= {MAIN_MEM_ADDR_WIDTH{1'b0}};
    rpg_busy <= 1'b0;
    rd_buff_rden <= 1'b0;
    wpg_st_addr <= {MAIN_MEM_ADDR_WIDTH{1'b0}};
    wpg_burst_length <= {MAIN_MEM_ADDR_WIDTH{1'b0}};
    wpg_busy <= 1'b0;
    wr_buff_wren <= 1'b0;
    wr_buff_wdata <= {MAIN_MEM_DATA_WIDTH{1'b0}};
    busy <= 1'b0;
    done <= 1'b0;
    curr_state <= STATE_IDLE;
    rdata <= {MAIN_MEM_DATA_WIDTH{1'b0}};
    row_cnt <= {MAXIMUM_INCREMENTAL_HEIGHT_BITS{1'b0}};
    col_cnt <= {MAXIMUM_INCREMENTAL_WIDTH_BITS{1'b0}};
    hor_incr_type <= 1'b0;
    ver_incr_type <= 1'b0;
    graph_type <= 1'b0;
    mask_type <= 1'b0;
    mask <= {MAIN_MEM_DATA_WIDTH{1'b0}};
    mask_cnt <= {MAXIMUM_INCREMENTAL_WIDTH_BITS{1'b0}};
    mask_addr <= {MAIN_MEM_ADDR_WIDTH{1'b0}};
    obj_addr <= {MAIN_MEM_ADDR_WIDTH{1'b0}};
    ss_start <= 1'b0;
  end else begin
    done <= 1'b0; // this should be a pulse
    if(rpg_ack)
      rpg_busy <= 1'b0;
    if(wpg_ack)
      wpg_busy <= 1'b0;

    case(curr_state)

      STATE_IDLE: begin
        if(start) begin
          rpg_st_addr <= obj_st_pix;
          rpg_burst_length <= obj_width;
          wpg_st_addr <= obj_st_pix;
          wpg_burst_length <= obj_width;
          mask_addr <= obj_st_mask;
          obj_addr <= obj_st_pix;
          hor_incr_type <= obj_type == HORIZONTAL_INCREMENTAL_TYPE;
          ver_incr_type <= obj_type == VERTICAL_INCREMENTAL_TYPE;
          graph_type <= obj_type == GRAPH_TYPE;
          mask_type <= obj_type == MASK_TYPE;
          row_cnt <= obj_height;
          col_cnt <= {MAXIMUM_INCREMENTAL_WIDTH_BITS{1'b0}};
          mask_cnt <= {MAXIMUM_INCREMENTAL_WIDTH_BITS{1'b0}};
          busy <= 1'b1;
          curr_state <= STATE_START;
        end
      end

      STATE_START: begin
        curr_state <= mask_type ? STATE_START_PG_MASK : STATE_START_PG;
      end

      STATE_START_PG_MASK: begin // starts rpg for reading mask
        rpg_busy <= 1'b1;
        rpg_st_addr <= mask_addr;
        mask_addr <= mask_addr + obj_width;
        curr_state <= STATE_RD_MASK;
      end

      STATE_RD_MASK: begin
        if((!rpg_busy) && (mask_cnt == obj_width) && rd_buff_empty) begin
          mask_cnt <= {MAXIMUM_INCREMENTAL_WIDTH_BITS{1'b0}};
          rpg_st_addr <= obj_addr;
          curr_state <= STATE_START_PG;
        end else if ((mask_cnt < obj_width) && (!rd_buff_empty)) begin
          if(!rd_buff_empty) begin
            rd_buff_rden <= 1'b1;
            rdata <= rd_buff_rdata;
            curr_state <= STATE_RD_MASK2;
          end
        end
      end

      STATE_RD_MASK2: begin
        rd_buff_rden <= 1'b0;
        mask <= {mask, rdata[0]};
        mask_cnt <= mask_cnt + 1'b1;
        curr_state <= STATE_RD_MASK;
      end

      STATE_START_PG: begin
        if(row_cnt > 0) begin
          rpg_busy <= 1'b1;
          wpg_busy <= 1'b1;
          curr_state <= STATE_WAIT_PG;
        end else begin
          ss_start <= 1'b1;
          if(ss_busy) begin
            ss_start <= 1'b0;
            curr_state <= STATE_WAIT_SS_DONE;
          end
        end
      end

      STATE_WAIT_SS_DONE: begin // we will keep the busy on the drawing circuit asserted until the screen system completes the screen refreshing process, not necessary, but it is safer
        if(!ss_busy) begin
          busy <= 1'b0;
          done <= 1'b1;
          curr_state <= STATE_IDLE;
        end
      end

      STATE_WAIT_PG: begin
        if(!rd_buff_empty) begin
          obj_addr <= obj_addr + ACTIVE_SCREEN_WIDTH;
          rpg_st_addr <= rpg_st_addr + ACTIVE_SCREEN_WIDTH;
          wpg_st_addr <= wpg_st_addr + ACTIVE_SCREEN_WIDTH;
          curr_state <= STATE_RD_DATA;
          rd_buff_rden <= 1'b1; // read the first pixel of a row
          rdata <= rd_buff_rdata;
        end
      end

      STATE_RD_DATA: begin
        rd_buff_rden <= 1'b0;
        if((!wr_buff_full) || ((col_cnt == {MAXIMUM_INCREMENTAL_WIDTH_BITS{1'b0}}) && graph_type)) begin
          curr_state <= STATE_WR_DATA;
          if(!((col_cnt == {MAXIMUM_INCREMENTAL_WIDTH_BITS{1'b0}}) && graph_type))
            wr_buff_wren <= 1'b1; // if graph, we will not set wr_buff_wren if this is the first pixel, as we are shifting to the left
          if(hor_incr_type) // horizontal incremental object type - if horizontal, current object value is based on columns
            wr_buff_wdata <= {col_cnt <= obj_value, rdata[MAIN_MEM_DATA_WIDTH-2:0]};
          else if(ver_incr_type) // vertical incremental object type - if vertical, current object value is based on rows
            wr_buff_wdata <= {row_cnt <= obj_value, rdata[MAIN_MEM_DATA_WIDTH-2:0]};
          else if(graph_type) // graph object type - if graph, we want to draw only last bit, and shift the rest to the left
            wr_buff_wdata <= {rdata[MAIN_MEM_DATA_WIDTH-1], rdata[MAIN_MEM_DATA_WIDTH-2:0]}; // we are only shifting the mask on/off bit in the graphs
          else if(mask_type)
            wr_buff_wdata <= {mask[0], rdata[MAIN_MEM_DATA_WIDTH-2:0]};
          mask <= mask >> 1'b1;
        end
      end

      STATE_WR_DATA: begin
        wr_buff_wren <= 1'b0;
        col_cnt <= col_cnt + 1'b1;
        curr_state <= STATE_TMP;
      end

      STATE_TMP: begin
        if(graph_type ? (col_cnt == (obj_width + 1'b1)) : (col_cnt == obj_width)) begin // as we are shifting to the left, when graph, we access STATE_WR_DATA one extra time
          if((!wpg_busy) && (!rpg_busy)) begin
            row_cnt <= row_cnt - 1'b1;
            col_cnt <= {MAXIMUM_INCREMENTAL_WIDTH_BITS{1'b0}};
            curr_state <= mask_type ? STATE_START_PG_MASK : STATE_START_PG;
          end
        end else begin // if row is not done
          if(col_cnt == obj_width) begin // if it is the last pixel of a row in a graph, we go directly to the STATE_WR_DATA
            if(!wr_buff_full) begin
              curr_state <= STATE_WR_DATA;
              wr_buff_wren <= 1'b1; // we write if we are in the last pixel of a row in a graph
              wr_buff_wdata <= {row_cnt <= obj_value, rdata[MAIN_MEM_DATA_WIDTH-2:0]}; // we compute the value of the last pixel of a row in a graph
            end
          end else begin // if not a graph, we read the last pixel
            if(!rd_buff_empty) begin
              curr_state <= STATE_RD_DATA;
              rdata <= rd_buff_rdata;
              rd_buff_rden <= 1'b1; // we read if not last pixel of a row in a graph
            end
          end
        end
      end

    endcase

  end
end

endmodule
