`define PIXEL       8
`define IMAGE_WIDTH 258

// 3x3 shift-register sliding window
// Three parallel 3-stage chains, one per image row
// shift_en must be asserted every COMPUTE cycle by control_unit
// window_valid asserts after 3 pixels have shifted through all stages

module sliding_window(
  input  clk, rst,
  input  shift_en,
  input  [`PIXEL-1:0] row0_pixel,   // from line_buffer_0 (row N-2)
  input  [`PIXEL-1:0] row1_pixel,   // from line_buffer_1 (row N-1)
  input  [`PIXEL-1:0] row2_pixel,   // live current-row pixel
  output wire [`PIXEL-1:0] w00, w01, w02,
  output wire [`PIXEL-1:0] w10, w11, w12,
  output wire [`PIXEL-1:0] w20, w21, w22,
  output reg  window_valid
);

  // Shift-register FFs: _a=newest, _b=middle, _c=oldest
  reg [`PIXEL-1:0] r0a, r0b, r0c;
  reg [`PIXEL-1:0] r1a, r1b, r1c;
  reg [`PIXEL-1:0] r2a, r2b, r2c;

  reg [1:0] fill_cnt;   // saturates at 3

  always@(posedge clk or negedge rst) begin
    if(!rst) begin
      r0a<=8'h00; r0b<=8'h00; r0c<=8'h00;
      r1a<=8'h00; r1b<=8'h00; r1c<=8'h00;
      r2a<=8'h00; r2b<=8'h00; r2c<=8'h00;
      fill_cnt     <= 2'd0;
      window_valid <= 1'b0;
    end
    else begin
      if(shift_en) begin
        // Row 0 chain (from LB0, row N-2)
        r0c <= r0b; r0b <= r0a; r0a <= row0_pixel;
        // Row 1 chain (from LB1, row N-1)
        r1c <= r1b; r1b <= r1a; r1a <= row1_pixel;
        // Row 2 chain (live current row)
        r2c <= r2b; r2b <= r2a; r2a <= row2_pixel;

        if(fill_cnt < 2'd3)
          fill_cnt <= fill_cnt + 2'd1;

        if(fill_cnt == 2'd2)
          window_valid <= 1'b1;
      end
    end
  end

  // Column 0 = oldest (FF_C), Column 1 = middle (FF_B), Column 2 = newest (FF_A)
  assign w00=r0c; assign w01=r0b; assign w02=r0a;
  assign w10=r1c; assign w11=r1b; assign w12=r1a;
  assign w20=r2c; assign w21=r2b; assign w22=r2a;

endmodule
