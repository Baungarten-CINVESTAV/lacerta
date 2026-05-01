//////////////////////////////////////////////////////////////////////////////
// Company: Mifral
// Engineer: Miguel Rivera
// 
// Design Name: lacerta
// Module Name: color_mapping_table
//
// Description:
// this module is a look up table that stores all the 16-bit encoded RGB
// colors that are used in the current gui, it is written by using commands
// coming from command_arbiter_decoder, and it is read by tft_control_fsm by
// using the color selector read from the main memory
/////////////////////////////////////////////////////////////////////////////

module color_mapping_table (
  input wire clk,
  input wire arst_n,
  input wire cm_wren,
  input wire [$clog2(COLOR_MAP_NUM) - 1 : 0] cm_addr,
  input wire [15 : 0] cm_data, // 16 bits per pixel RGB565
  input [$clog2(COLOR_MAP_NUM) - 1 : 0] color_sel,
  output wire [15 : 0] color
);

  reg [15 : 0] color_map [COLOR_MAP_NUM];
  integer i; // TODO: need to fix this for synthesis
  always@(posedge clk, negedge arst_n) begin
    if(!arst_n) begin
      for(i = 0; i < COLOR_MAP_NUM; i = i + 1) begin
        color_map[i] <= 16'd0;
      end
    end else begin
      if(cm_wren) begin
        color_map[cm_addr] <= cm_data;
      end
    end
  end

  assign color = color_map[color_sel];

endmodule
