`define PIXEL   8
`define WEIGHT  8
`define PRODUCT 24

// 3x3 systolic array — 9 PEs operating in parallel (weight-stationary broadcast)
// PE(r,c) gets window pixel w[r][c] and weight wt(r*3+c)
// All 9 products go simultaneously to adder_tree

module systolic_array_3x3(
  input  clk, rst,
  input  load_weight,
  input  pixel_valid,
  // Pixel inputs from sliding window
  input  [`PIXEL-1:0]  w00, w01, w02,
  input  [`PIXEL-1:0]  w10, w11, w12,
  input  [`PIXEL-1:0]  w20, w21, w22,
  // Weight inputs from weight_rom
  input  signed [`WEIGHT-1:0] wt0, wt1, wt2,
  input  signed [`WEIGHT-1:0] wt3, wt4, wt5,
  input  signed [`WEIGHT-1:0] wt6, wt7, wt8,
  // Product outputs to adder_tree
  output wire signed [`PRODUCT-1:0] p0, p1, p2,
  output wire signed [`PRODUCT-1:0] p3, p4, p5,
  output wire signed [`PRODUCT-1:0] p6, p7, p8,
  output wire products_valid
);

  wire [8:0] pe_valid;
  assign products_valid = pe_valid[0];   // all PEs share the same latency

  // Row 0
  pe pe00(.clk(clk),.rst(rst),.load_weight(load_weight),
          .weight_in(wt0),.pixel_in(w00),.pixel_valid(pixel_valid),
          .product_out(p0),.out_valid(pe_valid[0]));
  pe pe01(.clk(clk),.rst(rst),.load_weight(load_weight),
          .weight_in(wt1),.pixel_in(w01),.pixel_valid(pixel_valid),
          .product_out(p1),.out_valid(pe_valid[1]));
  pe pe02(.clk(clk),.rst(rst),.load_weight(load_weight),
          .weight_in(wt2),.pixel_in(w02),.pixel_valid(pixel_valid),
          .product_out(p2),.out_valid(pe_valid[2]));

  // Row 1
  pe pe10(.clk(clk),.rst(rst),.load_weight(load_weight),
          .weight_in(wt3),.pixel_in(w10),.pixel_valid(pixel_valid),
          .product_out(p3),.out_valid(pe_valid[3]));
  pe pe11(.clk(clk),.rst(rst),.load_weight(load_weight),
          .weight_in(wt4),.pixel_in(w11),.pixel_valid(pixel_valid),
          .product_out(p4),.out_valid(pe_valid[4]));
  pe pe12(.clk(clk),.rst(rst),.load_weight(load_weight),
          .weight_in(wt5),.pixel_in(w12),.pixel_valid(pixel_valid),
          .product_out(p5),.out_valid(pe_valid[5]));

  // Row 2
  pe pe20(.clk(clk),.rst(rst),.load_weight(load_weight),
          .weight_in(wt6),.pixel_in(w20),.pixel_valid(pixel_valid),
          .product_out(p6),.out_valid(pe_valid[6]));
  pe pe21(.clk(clk),.rst(rst),.load_weight(load_weight),
          .weight_in(wt7),.pixel_in(w21),.pixel_valid(pixel_valid),
          .product_out(p7),.out_valid(pe_valid[7]));
  pe pe22(.clk(clk),.rst(rst),.load_weight(load_weight),
          .weight_in(wt8),.pixel_in(w22),.pixel_valid(pixel_valid),
          .product_out(p8),.out_valid(pe_valid[8]));

endmodule
