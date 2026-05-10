`define PRODUCT    24
`define SUM        27

// 4-level pipelined adder tree: reduces 9x24-bit signed products to one 27-bit sum
// Pipeline latency = 4 cycles; one result per clock after fill

module adder_tree(
  input  clk, rst,
  input  signed [`PRODUCT-1:0] p0, p1, p2, p3, p4, p5, p6, p7, p8,
  input  valid_in,
  output reg signed [`SUM-1:0] sum_out,
  output reg valid_out
);

  // Level 1 — 4 pair adders + p8 pass-through
  reg signed [24:0] l1_s01, l1_s23, l1_s45, l1_s67;
  reg signed [23:0] l1_p8;
  reg               l1_valid;

  always@(posedge clk or negedge rst) begin
    if(!rst) begin
      l1_s01   <= 25'sd0; l1_s23  <= 25'sd0;
      l1_s45   <= 25'sd0; l1_s67  <= 25'sd0;
      l1_p8    <= 24'sd0; l1_valid <= 1'b0;
    end
    else begin
      l1_valid <= valid_in;
      l1_s01   <= {{1{p0[`PRODUCT-1]}}, p0} + {{1{p1[`PRODUCT-1]}}, p1};
      l1_s23   <= {{1{p2[`PRODUCT-1]}}, p2} + {{1{p3[`PRODUCT-1]}}, p3};
      l1_s45   <= {{1{p4[`PRODUCT-1]}}, p4} + {{1{p5[`PRODUCT-1]}}, p5};
      l1_s67   <= {{1{p6[`PRODUCT-1]}}, p6} + {{1{p7[`PRODUCT-1]}}, p7};
      l1_p8    <= p8;
    end
  end

  // Level 2 — 2 quad adders + p8 pass-through
  reg signed [25:0] l2_s0123, l2_s4567;
  reg signed [23:0] l2_p8;
  reg               l2_valid;

  always@(posedge clk or negedge rst) begin
    if(!rst) begin
      l2_s0123 <= 26'sd0; l2_s4567 <= 26'sd0;
      l2_p8    <= 24'sd0; l2_valid  <= 1'b0;
    end
    else begin
      l2_valid  <= l1_valid;
      l2_s0123  <= {{1{l1_s01[24]}}, l1_s01} + {{1{l1_s23[24]}}, l1_s23};
      l2_s4567  <= {{1{l1_s45[24]}}, l1_s45} + {{1{l1_s67[24]}}, l1_s67};
      l2_p8     <= l1_p8;
    end
  end

  // Level 3 — 1 octet adder + p8 pass-through
  reg signed [26:0] l3_s01234567;
  reg signed [23:0] l3_p8;
  reg               l3_valid;

  always@(posedge clk or negedge rst) begin
    if(!rst) begin
      l3_s01234567 <= 27'sd0;
      l3_p8        <= 24'sd0;
      l3_valid     <= 1'b0;
    end
    else begin
      l3_valid     <= l2_valid;
      l3_s01234567 <= {{1{l2_s0123[25]}}, l2_s0123}
                    + {{1{l2_s4567[25]}}, l2_s4567};
      l3_p8        <= l2_p8;
    end
  end

  // Level 4 — final sum
  always@(posedge clk or negedge rst) begin
    if(!rst) begin
      sum_out   <= `SUM'sd0;
      valid_out <= 1'b0;
    end
    else begin
      valid_out <= l3_valid;
      sum_out   <= l3_s01234567 + {{3{l3_p8[`PRODUCT-1]}}, l3_p8};
    end
  end

endmodule
