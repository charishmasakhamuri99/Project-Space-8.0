module systolic_array_3x3 #(
    parameter PIXEL = 8,
    parameter WEIGHT = 8,
    parameter PRODUCT = 24
)(
    input  logic clk, rst, load_weight, pixel_valid,
    input  logic [PIXEL-1:0]  w00, w01, w02, w10, w11, w12, w20, w21, w22,
    input  logic signed [WEIGHT-1:0] wt0, wt1, wt2, wt3, wt4, wt5, wt6, wt7, wt8,
    output logic signed [PRODUCT-1:0] p0, p1, p2, p3, p4, p5, p6, p7, p8,
    output logic products_valid
);

    logic [8:0] pe_valid;
    assign products_valid = pe_valid[0];

    pe #(PIXEL, WEIGHT, PRODUCT) pe00(clk, rst, load_weight, wt0, w00, pixel_valid, p0, pe_valid[0]);
    pe #(PIXEL, WEIGHT, PRODUCT) pe01(clk, rst, load_weight, wt1, w01, pixel_valid, p1, pe_valid[1]);
    pe #(PIXEL, WEIGHT, PRODUCT) pe02(clk, rst, load_weight, wt2, w02, pixel_valid, p2, pe_valid[2]);
    pe #(PIXEL, WEIGHT, PRODUCT) pe10(clk, rst, load_weight, wt3, w10, pixel_valid, p3, pe_valid[3]);
    pe #(PIXEL, WEIGHT, PRODUCT) pe11(clk, rst, load_weight, wt4, w11, pixel_valid, p4, pe_valid[4]);
    pe #(PIXEL, WEIGHT, PRODUCT) pe12(clk, rst, load_weight, wt5, w12, pixel_valid, p5, pe_valid[5]);
    pe #(PIXEL, WEIGHT, PRODUCT) pe20(clk, rst, load_weight, wt6, w20, pixel_valid, p6, pe_valid[6]);
    pe #(PIXEL, WEIGHT, PRODUCT) pe21(clk, rst, load_weight, wt7, w21, pixel_valid, p7, pe_valid[7]);
    pe #(PIXEL, WEIGHT, PRODUCT) pe22(clk, rst, load_weight, wt8, w22, pixel_valid, p8, pe_valid[8]);
endmodule
