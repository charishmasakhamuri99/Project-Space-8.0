module sliding_window #(
  parameter PIXEL_W     = 8,
  parameter IMAGE_WIDTH = 258
)(
  input  wire                  clk,
  input  wire                  rst,
  input  wire                  shift_en,
  input  wire [PIXEL_W-1:0]    row0_pixel,
  input  wire [PIXEL_W-1:0]    row1_pixel,
  input  wire [PIXEL_W-1:0]    row2_pixel,
  output wire [PIXEL_W-1:0]    w00, w01, w02,
  output wire [PIXEL_W-1:0]    w10, w11, w12,
  output wire [PIXEL_W-1:0]    w20, w21, w22,
  output reg                   window_valid
);

  reg [PIXEL_W-1:0] r0a, r0b, r0c;
  reg [PIXEL_W-1:0] r1a, r1b, r1c;
  reg [PIXEL_W-1:0] r2a, r2b, r2c;

  reg [1:0] fill_cnt;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      r0a <= {PIXEL_W{1'b0}}; r0b <= {PIXEL_W{1'b0}}; r0c <= {PIXEL_W{1'b0}};
      r1a <= {PIXEL_W{1'b0}}; r1b <= {PIXEL_W{1'b0}}; r1c <= {PIXEL_W{1'b0}};
      r2a <= {PIXEL_W{1'b0}}; r2b <= {PIXEL_W{1'b0}}; r2c <= {PIXEL_W{1'b0}};
      fill_cnt     <= 2'd0;
      window_valid <= 1'b0;
    end else begin
      if (shift_en) begin
        r0c <= r0b; r0b <= r0a; r0a <= row0_pixel;
        r1c <= r1b; r1b <= r1a; r1a <= row1_pixel;
        r2c <= r2b; r2b <= r2a; r2a <= row2_pixel;

        if (fill_cnt < 2'd3)
          fill_cnt <= fill_cnt + 2'd1;

        if (fill_cnt == 2'd2)
          window_valid <= 1'b1;
      end
    end
  end

  assign w00 = r0c; assign w01 = r0b; assign w02 = r0a;
  assign w10 = r1c; assign w11 = r1b; assign w12 = r1a;
  assign w20 = r2c; assign w21 = r2b; assign w22 = r2a;

endmodule
