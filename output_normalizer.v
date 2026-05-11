module output_normalizer #(
  parameter SUM = 27,
  parameter PIXEL = 8
)(
  input  logic signed [SUM-1:0] raw_result,
  input  logic mode,
  input  logic valid_in,
  output logic [PIXEL-1:0] pixel_out,
  output logic valid_out
);

  assign valid_out = valid_in;

  logic signed [SUM-1:0] abs_val;
  logic signed [SUM-1:0] max_pixel;
  logic signed [SUM-1:0] gauss_shifted;

  assign abs_val = raw_result[SUM-1] ?
                   (~raw_result + 1'b1) :
                    raw_result;

  assign gauss_shifted =
          {{4{raw_result[SUM-1]}}, raw_result[SUM-1:4]};

  assign max_pixel =
          {{(SUM-8){1'b0}}, 8'd255};

  always_comb begin
    if(!mode) begin
      // Gaussian mode
      if(gauss_shifted[SUM-1])
        pixel_out = {PIXEL{1'b0}};
      else if(gauss_shifted > max_pixel)
        pixel_out = {PIXEL{1'b1}};
      else
        pixel_out = gauss_shifted[PIXEL-1:0];
    end
    else begin
      // Sobel mode
      if(abs_val > max_pixel)
        pixel_out = {PIXEL{1'b1}};
      else
        pixel_out = abs_val[PIXEL-1:0];
    end
  end

endmodule
