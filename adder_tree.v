module adder_tree #(
  parameter PRODUCT_W = 24,
  parameter SUM_W     = 27
)(
  input  wire                      clk,
  input  wire                      rst,
  input  wire signed [PRODUCT_W-1:0] p0, p1, p2, p3, p4, p5, p6, p7, p8,
  input  wire                      valid_in,
  output reg  signed [SUM_W-1:0]   sum_out,
  output reg                       valid_out
);

  reg signed [PRODUCT_W:0]   l1_s01, l1_s23, l1_s45, l1_s67;
  reg signed [PRODUCT_W-1:0] l1_p8;
  reg                         l1_valid;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      l1_s01   <= {(PRODUCT_W+1){1'b0}};
      l1_s23   <= {(PRODUCT_W+1){1'b0}};
      l1_s45   <= {(PRODUCT_W+1){1'b0}};
      l1_s67   <= {(PRODUCT_W+1){1'b0}};
      l1_p8    <= {PRODUCT_W{1'b0}};
      l1_valid <= 1'b0;
    end else begin
      l1_valid <= valid_in;
      l1_s01   <= {{1{p0[PRODUCT_W-1]}}, p0} + {{1{p1[PRODUCT_W-1]}}, p1};
      l1_s23   <= {{1{p2[PRODUCT_W-1]}}, p2} + {{1{p3[PRODUCT_W-1]}}, p3};
      l1_s45   <= {{1{p4[PRODUCT_W-1]}}, p4} + {{1{p5[PRODUCT_W-1]}}, p5};
      l1_s67   <= {{1{p6[PRODUCT_W-1]}}, p6} + {{1{p7[PRODUCT_W-1]}}, p7};
      l1_p8    <= p8;
    end
  end

  reg signed [PRODUCT_W+1:0] l2_s0123, l2_s4567;
  reg signed [PRODUCT_W-1:0] l2_p8;
  reg                          l2_valid;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      l2_s0123 <= {(PRODUCT_W+2){1'b0}};
      l2_s4567 <= {(PRODUCT_W+2){1'b0}};
      l2_p8    <= {PRODUCT_W{1'b0}};
      l2_valid <= 1'b0;
    end else begin
      l2_valid  <= l1_valid;
      l2_s0123  <= {{1{l1_s01[PRODUCT_W]}}, l1_s01} + {{1{l1_s23[PRODUCT_W]}}, l1_s23};
      l2_s4567  <= {{1{l1_s45[PRODUCT_W]}}, l1_s45} + {{1{l1_s67[PRODUCT_W]}}, l1_s67};
      l2_p8     <= l1_p8;
    end
  end

  reg signed [PRODUCT_W+2:0] l3_s01234567;
  reg signed [PRODUCT_W-1:0] l3_p8;
  reg                          l3_valid;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      l3_s01234567 <= {(PRODUCT_W+3){1'b0}};
      l3_p8        <= {PRODUCT_W{1'b0}};
      l3_valid     <= 1'b0;
    end else begin
      l3_valid     <= l2_valid;
      l3_s01234567 <= {{1{l2_s0123[PRODUCT_W+1]}}, l2_s0123}
                    + {{1{l2_s4567[PRODUCT_W+1]}}, l2_s4567};
      l3_p8        <= l2_p8;
    end
  end

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      sum_out   <= {SUM_W{1'b0}};
      valid_out <= 1'b0;
    end else begin
      valid_out <= l3_valid;
      sum_out   <= l3_s01234567 + {{(SUM_W-PRODUCT_W){l3_p8[PRODUCT_W-1]}}, l3_p8};
    end
  end

endmodule
