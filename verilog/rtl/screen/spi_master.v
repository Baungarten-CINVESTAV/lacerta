///////////////////////////////////////////////////////////////////////////////////////
// Company: Mifral
// Engineer: Miguel Rivera
// 
// Design Name: lacerta
// Module Name: spi_master
//
// Description:
// this module implements a very basic spi master transmitter for issuing commands 
// and data to the tft screen, it uses spi mode 0, and is controlled by
// tft_control_fsm, we can easily control the sck frequency by configuring
// clk_divider from command_arbiter_decoder
///////////////////////////////////////////////////////////////////////////////////////

module spi_master (
  input wire clk,
  input wire arst_n,
  // Control ports
  input wire [5:0] clock_divider,
  input wire tnsm,
  input wire [7:0] tnsm_data,
  output reg tnsm_ack,
  output wire tnsm_busy,
  output reg tnsm_done,
  // SPI ports
  output reg sck,
  output reg ss,
  output reg mosi
);

parameter STATE_TNSM_IDLE = 2'b00;
parameter STATE_TNSM_SAFETY_DELAY = 2'b01;
parameter STATE_TNSM_ACTIVE = 2'b10;
parameter STATE_TNSM_STOP = 2'b11;

// clock divider signals
reg [5:0] clk_divider_cnt; 
reg sck_d; // this flops the actual sck edge
wire clk_en; // this will be set when transmitting logic must drive based on clock_divider
wire tnsm_edge;

reg [2:0] bitcnt;
reg [7:0] tnsm_data_r;
reg [1:0] state;

// clock divider logic
always@(posedge clk, negedge arst_n) begin
  if(!arst_n) begin
    clk_divider_cnt <= 6'd0;
  end else begin
    if(tnsm_busy) begin
      if(clk_divider_cnt == clock_divider)
        clk_divider_cnt <= 6'd0;
      else
        clk_divider_cnt <= clk_divider_cnt + 1'b1;
    end else begin
      clk_divider_cnt <= 6'd0;
    end
  end
end

always@(posedge clk, negedge arst_n) begin
  if(!arst_n) begin
    sck <= 1'b0;
    sck_d <= 1'b0;
  end else begin
    sck_d <= sck;
    if(~tnsm_busy)
      sck <= 1'b0;
    else if(clk_en && (state == STATE_TNSM_ACTIVE))
      sck <= ~sck;
  end
end

assign clk_en = (clk_divider_cnt == clock_divider);
assign tnsm_edge = sck_d && (!sck); // for spi mode 0, we drive on the negative edge of sck

// Transmitter procedural block
	always@(posedge clk, negedge arst_n) begin
		if(!arst_n) begin
      ss <= 1'b1;
			mosi <= 1'b0;
			bitcnt <= 3'd0;
			tnsm_data_r <= 8'd0;
      tnsm_done <= 1'b0;
      tnsm_ack <= 1'b0;
			state <= STATE_TNSM_IDLE;
		end	else begin
      tnsm_done <= 1'b0;
      tnsm_ack <= 1'b0;

			case(state)

				STATE_TNSM_IDLE: begin
          if(tnsm) begin
            ss <= 1'b0;
            state <= STATE_TNSM_SAFETY_DELAY;
            tnsm_data_r <= {tnsm_data[6:0], 1'b0}; // we are sending the MSB of tnsm_data in this clock cycle
            mosi <= tnsm_data[7]; // msb first for most SPI TFT screens
            bitcnt <= 3'd0; // we already drive the MSB in this clock cycle
            tnsm_ack <= 1'b1;
          end
        end

        STATE_TNSM_SAFETY_DELAY: begin
          if(clk_en) begin
            state <= STATE_TNSM_ACTIVE;
          end
        end

        STATE_TNSM_ACTIVE: begin
          if(tnsm_edge) begin
            mosi <= tnsm_data_r[7]; // msb first for most SPI TFT screens
            tnsm_data_r <= {tnsm_data_r[6:0], 1'b0}; // left shift
						bitcnt <= bitcnt + 3'd1;
            if(bitcnt == 3'd7) begin
              state <= STATE_TNSM_STOP;
            end
          end
        end

				STATE_TNSM_STOP: begin
          tnsm_done <= 1'b1;
          ss <= 1'b1;
          bitcnt <= 3'd0; // reset the bit counter
				  state <= STATE_TNSM_IDLE;
				end

			endcase

		end
	end

	assign tnsm_busy = state != STATE_TNSM_IDLE;

endmodule
