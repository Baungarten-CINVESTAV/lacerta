module mask_generator(
  output wire [3:0] ostate,
  input wire clk,
  input wire arst_n,
  input wire start,
  input wire [3:0] obj_type, // 0 - boolean, 1 vertical incremental, 2 horizontal incremental
  input wire [10:0] obj_width,
  input wire [10:0] obj_height,
  input wire [21:0] obj_st_pix, // starting pixel
  input wire [21:0] obj_st_mask,
  input wire [14:0] obj_value,
  output reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] rpg_st_addr,
  output reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] rpg_burst_length,
  output reg rpg_busy,
  input wire rpg_ack,
  output wire rd_buff_rden,
  input wire [MAIN_MEM_DATA_WIDTH - 1 : 0] rd_buff_rdata,
  input wire rd_buff_empty,
  output reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] wpg_st_addr,
  output reg [MAIN_MEM_ADDR_WIDTH - 1 : 0] wpg_burst_length,
  output reg wpg_busy,
  input wire wpg_ack,
  output wire wr_buff_wren,
  output reg [MAIN_MEM_DATA_WIDTH - 1 : 0] wr_buff_wdata,
  input wire wr_buff_full,
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

localparam BOOLEAN_TYPE = 0;
localparam HORIZONTAL_INCREMENTAL_TYPE = 1;
localparam VERTICAL_INCREMENTAL_TYPE = 2;
localparam GRAPH_TYPE = 3;
localparam MASK_TYPE = 4; // like 7 segment displays
localparam MAXIMUM_INCREMENTAL_WIDTH = 500;
localparam MAXIMUM_INCREMENTAL_HEIGHT = 500;
localparam MAXIMUM_INCREMENTAL_WIDTH_BITS = $clog2(MAXIMUM_INCREMENTAL_WIDTH);
localparam MAXIMUM_INCREMENTAL_HEIGHT_BITS = $clog2(MAXIMUM_INCREMENTAL_HEIGHT);
localparam IMAGE_WIDTH = 640;
localparam IMAGE_HEIGHT = 480;

reg [3:0] curr_state;
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
reg rd_buff_rden_r;
reg wr_buff_wren_r;
assign rd_buff_rden = rd_buff_rden_r && (!rd_buff_empty);
assign wr_buff_wren = wr_buff_wren_r && (!wr_buff_full);
assign ostate = curr_state;

always@(posedge clk, negedge arst_n) begin
  if(!arst_n) begin
    rpg_st_addr <= {MAIN_MEM_ADDR_WIDTH{1'b0}};
    rpg_burst_length <= {MAIN_MEM_ADDR_WIDTH{1'b0}};
    rpg_busy <= 1'b0;
    rd_buff_rden_r <= 1'b0;
    wpg_st_addr <= {MAIN_MEM_ADDR_WIDTH{1'b0}};
    wpg_burst_length <= {MAIN_MEM_ADDR_WIDTH{1'b0}};
    wpg_busy <= 1'b0;
    wr_buff_wren_r <= 1'b0;
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
  end else begin
    done <= 1'b0;
    rpg_busy <= rpg_ack ? 1'b0 : rpg_busy;
    wpg_busy <= wpg_ack ? 1'b0 : wpg_busy;

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
          row_cnt <= {MAXIMUM_INCREMENTAL_HEIGHT_BITS{1'b0}};
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
          rd_buff_rden_r <= 1'b1;
          curr_state <= STATE_RD_MASK2;
        end
      end

      STATE_RD_MASK2: begin
        rd_buff_rden_r <= !rd_buff_rden_r;
        if(rd_buff_rden) begin
          rd_buff_rden_r <= 1'b0;
          mask <= {mask, rd_buff_rdata[0]};
          mask_cnt <= mask_cnt + 1'b1;
          curr_state <= STATE_RD_MASK;
        end
      end

      STATE_START_PG: begin
        if(row_cnt < obj_height) begin
          rpg_busy <= 1'b1;
          wpg_busy <= 1'b1;
          curr_state <= STATE_WAIT_PG;
        end else begin
          busy <= 1'b0;
          done <= 1'b1;
          curr_state <= STATE_IDLE;
        end
      end

      STATE_WAIT_PG: begin
        obj_addr <= obj_addr - IMAGE_WIDTH;
        rpg_st_addr <= rpg_st_addr - IMAGE_WIDTH;
        wpg_st_addr <= wpg_st_addr - IMAGE_WIDTH;
        curr_state <= STATE_RD_DATA;
        rd_buff_rden_r <= 1'b1; // read the first pixel of a row
      end

      STATE_RD_DATA: begin
        rd_buff_rden_r <= !rd_buff_rden_r;
        if(rd_buff_rden) begin
          rd_buff_rden_r <= 1'b0;
          rdata <= rd_buff_rdata;
          curr_state <= STATE_WR_DATA;
          wr_buff_wren_r <= (col_cnt != {MAXIMUM_INCREMENTAL_WIDTH_BITS{1'b0}}) || (!graph_type); // if graph, we will not set wr_buff_wren_r if this is the first pixel, as we are shifting to the left
          if(hor_incr_type) // horizontal incremental object type - if horizontal, current object value is based on columns
            wr_buff_wdata <= {col_cnt <= obj_value, rd_buff_rdata[MAIN_MEM_DATA_WIDTH-2:0]};
          else if(ver_incr_type) // vertical incremental object type - if vertical, current object value is based on rows
            wr_buff_wdata <= {row_cnt <= obj_value, rd_buff_rdata[MAIN_MEM_DATA_WIDTH-2:0]};
          else if(graph_type) // graph object type - if graph, we want to draw only last bit, and shift the rest to the left
            wr_buff_wdata <= rd_buff_rdata;
          else if(mask_type)
            wr_buff_wdata <= {mask[0], rd_buff_rdata[MAIN_MEM_DATA_WIDTH-2:0]};
          mask <= mask >> 1'b1;
        end
      end

      STATE_WR_DATA: begin
        if(graph_type && (col_cnt == {MAXIMUM_INCREMENTAL_WIDTH_BITS{1'b0}})) begin // as graph are shifting, we want to write the first pixel value with the second read value
          col_cnt <= col_cnt + 1'b1;
          curr_state <= STATE_TMP;
        end else begin
          wr_buff_wren_r <= !wr_buff_wren_r;
          if(wr_buff_wren) begin
            wr_buff_wren_r <= 1'b0;
            col_cnt <= col_cnt + 1'b1;
            curr_state <= STATE_TMP;
          end
        end
      end

      STATE_TMP: begin
        if(graph_type ? (col_cnt == (obj_width + 'd1)) : (col_cnt == obj_width)) begin // as we are shifting to the left, when graph, we access STATE_WR_DATA one extra time
          if((!wpg_busy) && (!rpg_busy)) begin
            row_cnt <= row_cnt + 1'b1;
            col_cnt <= {MAXIMUM_INCREMENTAL_WIDTH_BITS{1'b0}};
            curr_state <= mask_type ? STATE_START_PG_MASK : STATE_START_PG;
          end
        end else begin // if row is not done
          curr_state <= (col_cnt == obj_width) ? STATE_WR_DATA : STATE_RD_DATA; // if it is the last pixel of a row in a graph, we go directly to the STATE_WR_DATA
          rd_buff_rden_r <= (col_cnt != obj_width); // we read if not last pixel of a row in a graph
          wr_buff_wren_r <= (col_cnt == obj_width); // we write if we are in the last pixel of a row in a graph
          wr_buff_wdata <= {row_cnt <= obj_value, rdata[MAIN_MEM_DATA_WIDTH-2:0]}; // we compute the value of the last pixel of a row in a graph
        end
      end

    endcase

  end
end

endmodule
