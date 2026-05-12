module adder_tree #(
    parameter PRODUCT = 24,
    parameter SUM = 27
)(
    input  logic clk, rst,
    input  logic signed [PRODUCT-1:0] p0, p1, p2, p3, p4, p5, p6, p7, p8,
    input  logic valid_in,
    output logic signed [SUM-1:0] sum_out,
    output logic valid_out
);

    logic signed [24:0] l1_s01, l1_s23, l1_s45, l1_s67;
    logic signed [23:0] l1_p8;
    logic               l1_valid;

    always_ff @(posedge clk or negedge rst) begin
        if(!rst) begin
            l1_s01   <= 25'sd0; l1_s23  <= 25'sd0;
            l1_s45   <= 25'sd0; l1_s67  <= 25'sd0;
            l1_p8    <= 24'sd0; l1_valid <= 1'b0;
        end
        else begin
            l1_valid <= valid_in;
            l1_s01   <= {{1{p0[PRODUCT-1]}}, p0} + {{1{p1[PRODUCT-1]}}, p1};
            l1_s23   <= {{1{p2[PRODUCT-1]}}, p2} + {{1{p3[PRODUCT-1]}}, p3};
            l1_s45   <= {{1{p4[PRODUCT-1]}}, p4} + {{1{p5[PRODUCT-1]}}, p5};
            l1_s67   <= {{1{p6[PRODUCT-1]}}, p6} + {{1{p7[PRODUCT-1]}}, p7};
            l1_p8    <= p8;
        end
    end

    logic signed [25:0] l2_s0123, l2_s4567;
    logic signed [23:0] l2_p8;
    logic               l2_valid;

    always_ff @(posedge clk or negedge rst) begin
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

    logic signed [26:0] l3_s01234567;
    logic signed [23:0] l3_p8;
    logic               l3_valid;

    always_ff @(posedge clk or negedge rst) begin
        if(!rst) begin
            l3_s01234567 <= 27'sd0;
            l3_p8        <= 24'sd0;
            l3_valid     <= 1'b0;
        end
        else begin
            l3_valid     <= l2_valid;
            l3_s01234567 <= {{1{l2_s0123[25]}}, l2_s0123} + {{1{l2_s4567[25]}}, l2_s4567};
            l3_p8        <= l2_p8;
        end
    end

    always_ff @(posedge clk or negedge rst) begin
        if(!rst) begin
            sum_out   <= {SUM{1'b0}};
            valid_out <= 1'b0;
        end
        else begin
            valid_out <= l3_valid;
            sum_out   <= l3_s01234567 + {{3{l3_p8[PRODUCT-1]}}, l3_p8};
        end
    end
endmodule
