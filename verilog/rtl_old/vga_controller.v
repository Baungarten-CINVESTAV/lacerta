module vga_controller(
  input clk,
  input arst_n,
  input enable,
  input [7:0] red,
  input [7:0] green,
  input [7:0] blue,
  input wire empty,
  output wire rden,
  input wire error_clr, // clears error flag
  output reg error, // tried to read when empty error
  // configuration registers
  input wire [9:0] hsync_deact,
  input wire [10:0] hsync_act,
  input wire [9:0] vsync_deact,
  input wire [10:0] vsync_act,
  // VGA signals
  output wire [7:0] ored,
  output wire [7:0] ogreen,
  output wire [7:0] oblue,
  output wire h_sync,
  output wire v_sync,
  output wire sync,
  output wire blank,
  output wire oclk
);

// VGA timing parameters for 640x480 60Hz
//	Horizontal Parameter ( Pixel )
localparam	H_SYNC_CYC	=	96;
localparam	H_SYNC_BACK	=	48;
localparam	H_SYNC_FRONT=	16;
localparam	H_SYNC_DEACT =	H_SYNC_CYC + H_SYNC_BACK + H_SYNC_FRONT; // total deactivated timing
localparam	H_SYNC_ACT	=	640 + 1;
localparam	H_SYNC_TOTAL=	H_SYNC_ACT + H_SYNC_DEACT;
//	Vertical Parameter ( Line )
localparam	V_SYNC_CYC	=	2;
localparam	V_SYNC_BACK	=	31;
localparam	V_SYNC_FRONT=	11;
localparam	V_SYNC_DEACT =	V_SYNC_CYC + V_SYNC_BACK + V_SYNC_FRONT; // total deactivated timing
localparam	V_SYNC_ACT	=	480 + 1;
localparam	V_SYNC_TOTAL=	V_SYNC_ACT + V_SYNC_DEACT;

reg clk_en; // As clk is 50 MHz, clk_en will be set every two clock cycles, thus 25MHz for 640x480
always@(posedge clk, negedge arst_n) begin
  if(!arst_n) begin
    clk_en <= 1'b0;
  end else begin
    clk_en <= ~clk_en;
  end
end

wire rden_; // internal read enable signal
wire h_active; // active area for horizontal probe
wire v_active; // active area for vertical probe
wire eof; // End of Frame - reset all counters
wire eor; // End of Row - We have to reset hcnt and increment vcnt
reg [10:0] hcnt; // counter of horizontal pixels
reg [10:0] vcnt; // counter of vertical pixels

always@(posedge clk, negedge arst_n) begin
  if(!arst_n) begin
    hcnt <= 11'd0;
  end else begin
    if(!enable) begin
      hcnt <= 11'd0;
    end else if(clk_en) begin
      hcnt <= hcnt + 11'd1;
      if(eof || eor)
        hcnt <= 11'd0;
    end
  end
end

always@(posedge clk, negedge arst_n) begin
  if(!arst_n) begin
    vcnt <= 11'd0;
  end else begin
    if(!enable) begin
      vcnt <= 11'd0;
    end else if(clk_en) begin
      if(eof)
        vcnt <= 11'd0;
      else if(eor)
        vcnt <= vcnt + 11'd1;
    end
  end
end

assign eor = hcnt == (hsync_deact + hsync_act);
assign eof = eor && (vcnt == (vsync_deact + vsync_act));
assign blank = h_sync && v_sync;
assign sync = 1'b0;
assign oclk = clk_en;
assign h_active = (hcnt > hsync_deact) && (hcnt < (hsync_act + hsync_deact));
assign v_active = (vcnt > vsync_deact) && (vcnt < (vsync_act + vsync_deact));
assign h_sync = h_active;
assign v_sync = v_active;
assign rden_ = enable && clk_en && h_active && v_active;
assign rden = rden_ && (!empty);
// Data read from input
assign ored = enable ? red : 8'h00;
assign ogreen = enable ? green : 8'h00;
assign oblue = enable ? blue : 8'h00;

always@(posedge clk, negedge arst_n) begin
  if(!arst_n) begin
    error <= 1'b0;
  end else begin
    if(rden_ && empty)
      error <= 1'b1;
    else if(error_clr)
      error <= 1'b0;
  end
end

endmodule
