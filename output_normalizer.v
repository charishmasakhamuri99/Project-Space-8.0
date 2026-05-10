`define SUM   27
`define PIXEL  8

// Combinational — converts 27-bit signed adder output to 8-bit unsigned pixel
// mode=0 (Gaussian): arithmetic right-shift by 4, then clamp [0,255]
// mode=1 (Sobel-X) : absolute value,           then clamp [0,255]

module output_normalizer(
  input  signed [`SUM-1:0] raw_result,
  input  mode,
  input  valid_in,
  output reg [`PIXEL-1:0] pixel_out,
  output wire valid_out
);

  assign valid_out = valid_in;

  wire signed [`SUM-1:0] abs_val;
  assign abs_val = raw_result[`SUM-1] ? (~raw_result + `SUM'd1) : raw_result;

  wire [`SUM-1:0] gauss_shifted;
  assign gauss_shifted = {{4{raw_result[`SUM-1]}}, raw_result[`SUM-1:4]};

  always@(*) begin
    if(!mode) begin
      // Gaussian — shift then clamp
      if(gauss_shifted[`SUM-1])
        pixel_out = 8'd0;
      else if(gauss_shifted > `SUM'd255)
        pixel_out = 8'd255;
      else
        pixel_out = gauss_shifted[`PIXEL-1:0];
    end
    else begin
      // Sobel — abs then clamp
      if(abs_val > `SUM'd255)
        pixel_out = 8'd255;
      else
        pixel_out = abs_val[`PIXEL-1:0];
    end
  end

endmodule
