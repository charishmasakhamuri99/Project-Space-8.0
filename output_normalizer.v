module output_normalizer #(
  parameter SUM_W   = 27,
  parameter PIXEL_W = 8
)(
  input  wire signed [SUM_W-1:0]  raw_result,
  input  wire                     mode,
  input  wire                     valid_in,
  output reg  [PIXEL_W-1:0]       pixel_out,
  output wire                     valid_out
);

  assign valid_out = valid_in;

  wire signed [SUM_W-1:0] abs_val;
  assign abs_val = raw_result[SUM_W-1] ? (~raw_result + {{(SUM_W-1){1'b0}}, 1'b1}) : raw_result;

  wire [SUM_W-1:0] gauss_shifted;
  assign gauss_shifted = {{4{raw_result[SUM_W-1]}}, raw_result[SUM_W-1:4]};

  always @(*) begin
    if (!mode) begin
      if (gauss_shifted[SUM_W-1])
        pixel_out = {PIXEL_W{1'b0}};
      else if (gauss_shifted > {{(SUM_W-8){1'b0}}, 8'd255})
        pixel_out = 8'd255;
      else
        pixel_out = gauss_shifted[PIXEL_W-1:0];
    end else begin
      if (abs_val > {{(SUM_W-8){1'b0}}, 8'd255})
        pixel_out = 8'd255;
      else
        pixel_out = abs_val[PIXEL_W-1:0];
    end
  end

endmodule
