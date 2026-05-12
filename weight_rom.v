module weight_rom #(
  parameter WEIGHT_W = 8
)(
  input  wire                        mode,
  output wire signed [WEIGHT_W-1:0]  w0, w1, w2,
  output wire signed [WEIGHT_W-1:0]  w3, w4, w5,
  output wire signed [WEIGHT_W-1:0]  w6, w7, w8
);

  wire signed [WEIGHT_W-1:0] gauss [8:0];
  assign gauss[0] = 8'sd1;  assign gauss[1] = 8'sd2;  assign gauss[2] = 8'sd1;
  assign gauss[3] = 8'sd2;  assign gauss[4] = 8'sd4;  assign gauss[5] = 8'sd2;
  assign gauss[6] = 8'sd1;  assign gauss[7] = 8'sd2;  assign gauss[8] = 8'sd1;

  wire signed [WEIGHT_W-1:0] sobel_x [8:0];
  assign sobel_x[0] = -8'sd1; assign sobel_x[1] = 8'sd0; assign sobel_x[2] = 8'sd1;
  assign sobel_x[3] = -8'sd2; assign sobel_x[4] = 8'sd0; assign sobel_x[5] = 8'sd2;
  assign sobel_x[6] = -8'sd1; assign sobel_x[7] = 8'sd0; assign sobel_x[8] = 8'sd1;

  assign w0 = mode ? sobel_x[0] : gauss[0];
  assign w1 = mode ? sobel_x[1] : gauss[1];
  assign w2 = mode ? sobel_x[2] : gauss[2];
  assign w3 = mode ? sobel_x[3] : gauss[3];
  assign w4 = mode ? sobel_x[4] : gauss[4];
  assign w5 = mode ? sobel_x[5] : gauss[5];
  assign w6 = mode ? sobel_x[6] : gauss[6];
  assign w7 = mode ? sobel_x[7] : gauss[7];
  assign w8 = mode ? sobel_x[8] : gauss[8];

endmodule
