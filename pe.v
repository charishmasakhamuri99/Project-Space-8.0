`define PIXEL      8
`define WEIGHT     8
`define PRODUCT    24

module pe(
  input clk, rst, load_weight,
  input      [`WEIGHT-1:0]  weight_in,
  input      [`PIXEL-1:0]   pixel_in,
  input                     pixel_valid,
  output reg signed [`PRODUCT-1:0] product_out,
  output reg                out_valid
);

  reg signed [`WEIGHT-1:0] weight_reg;

  // Weight latch
  always@(posedge clk or negedge rst) begin
    if(!rst)
      weight_reg <= `WEIGHT'sd0;
    else if(load_weight)
      weight_reg <= weight_in;
  end

  // Multiply stage — 8-bit signed x 8-bit unsigned, sign-extended to 24 bits
  always@(posedge clk or negedge rst) begin
    if(!rst) begin
      product_out <= `PRODUCT'sd0;
      out_valid   <= 1'b0;
    end
    else begin
      out_valid <= pixel_valid;
      if(pixel_valid)
        product_out <= {{8{weight_reg[`WEIGHT-1]}}, weight_reg}
                       * {{16{1'b0}}, pixel_in};
      else
        product_out <= `PRODUCT'sd0;
    end
  end

endmodule
