module pe #(
  parameter WEIGHT_W  = 8,
  parameter PIXEL_W   = 8,
  parameter PRODUCT_W = 24
)(
  input  wire                        clk,
  input  wire                        rst,
  input  wire                        load_weight,
  input  wire [WEIGHT_W-1:0]         weight_in,
  input  wire [PIXEL_W-1:0]          pixel_in,
  input  wire                        pixel_valid,
  output reg  signed [PRODUCT_W-1:0] product_out,
  output reg                         out_valid
);

  reg signed [WEIGHT_W-1:0] weight_reg;

  always @(posedge clk or negedge rst) begin
    if (!rst)
      weight_reg <= {WEIGHT_W{1'b0}};
    else if (load_weight)
      weight_reg <= weight_in;
  end

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      product_out <= {PRODUCT_W{1'b0}};
      out_valid   <= 1'b0;
    end else begin
      out_valid <= pixel_valid;
      if (pixel_valid)
        product_out <= {{(PRODUCT_W-WEIGHT_W){weight_reg[WEIGHT_W-1]}}, weight_reg}
                     * {{(PRODUCT_W-PIXEL_W){1'b0}}, pixel_in};
      else
        product_out <= {PRODUCT_W{1'b0}};
    end
  end

endmodule
