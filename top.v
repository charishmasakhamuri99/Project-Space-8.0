`timescale 1ns/1ps

module top #(
  parameter IMAGE_WIDTH   = 258,
  parameter IMAGE_HEIGHT  = 258,
  parameter OUTPUT_SIZE   = 256,
  parameter PIXEL_W       = 8,
  parameter WEIGHT_W      = 8,
  parameter PRODUCT_W     = 24,
  parameter SUM_W         = 27,
  parameter ADDER_LATENCY = 4,
  parameter SA_ROWS       = 3,
  parameter SA_COLS       = 3
)(
  input  wire        clk,
  input  wire        rst,
  input  wire        start,
  input  wire        mode,
  input  wire [7:0]  pixel_in,
  input  wire        pixel_valid,
  output wire        pixel_ready,
  output wire [7:0]  pixel_out,
  output wire        pixel_out_valid,
  output wire        done
);

  wire [$clog2(IMAGE_WIDTH)-1:0]  pic_wr_addr;
  wire [PIXEL_W-1:0]              pic_wr_data;
  wire                            pic_wr_en_lb0, pic_wr_en_lb1;
  wire [PIXEL_W-1:0]              pic_live_pixel;
  wire                            pic_live_valid;
  wire                            pic_row_done, pic_frame_done;
  wire [$clog2(IMAGE_HEIGHT)-1:0] pic_row_cnt;

  wire [PIXEL_W-1:0] lb0_rd_data, lb1_rd_data;

  wire                            cu_load_weight;
  wire                            cu_shift_en;
  wire                            cu_sw_flush;
  wire                            cu_pe_pixel_valid;
  wire                            cu_out_wr_en;
  wire                            cu_out_rd_en;
  wire [$clog2(IMAGE_WIDTH)-1:0]  cu_lb_rd_addr;
  wire [2:0]                      cu_state;

  wire [PIXEL_W-1:0] sw_w00, sw_w01, sw_w02;
  wire [PIXEL_W-1:0] sw_w10, sw_w11, sw_w12;
  wire [PIXEL_W-1:0] sw_w20, sw_w21, sw_w22;
  wire               sw_window_valid;

  wire signed [WEIGHT_W-1:0] wr_w0, wr_w1, wr_w2;
  wire signed [WEIGHT_W-1:0] wr_w3, wr_w4, wr_w5;
  wire signed [WEIGHT_W-1:0] wr_w6, wr_w7, wr_w8;

  wire [PIXEL_W-1:0]          sa_pixels  [SA_ROWS-1:0][SA_COLS-1:0];
  wire signed [WEIGHT_W-1:0]  sa_weights [SA_ROWS-1:0][SA_COLS-1:0];
  wire signed [PRODUCT_W-1:0] sa_products[SA_ROWS-1:0][SA_COLS-1:0];
  wire                        sa_products_valid;

  assign sa_pixels[0][0] = sw_w00; assign sa_pixels[0][1] = sw_w01; assign sa_pixels[0][2] = sw_w02;
  assign sa_pixels[1][0] = sw_w10; assign sa_pixels[1][1] = sw_w11; assign sa_pixels[1][2] = sw_w12;
  assign sa_pixels[2][0] = sw_w20; assign sa_pixels[2][1] = sw_w21; assign sa_pixels[2][2] = sw_w22;

  assign sa_weights[0][0] = wr_w0; assign sa_weights[0][1] = wr_w1; assign sa_weights[0][2] = wr_w2;
  assign sa_weights[1][0] = wr_w3; assign sa_weights[1][1] = wr_w4; assign sa_weights[1][2] = wr_w5;
  assign sa_weights[2][0] = wr_w6; assign sa_weights[2][1] = wr_w7; assign sa_weights[2][2] = wr_w8;

  wire signed [PRODUCT_W-1:0] at_p0, at_p1, at_p2;
  wire signed [PRODUCT_W-1:0] at_p3, at_p4, at_p5;
  wire signed [PRODUCT_W-1:0] at_p6, at_p7, at_p8;

  assign at_p0 = sa_products[0][0]; assign at_p1 = sa_products[0][1]; assign at_p2 = sa_products[0][2];
  assign at_p3 = sa_products[1][0]; assign at_p4 = sa_products[1][1]; assign at_p5 = sa_products[1][2];
  assign at_p6 = sa_products[2][0]; assign at_p7 = sa_products[2][1]; assign at_p8 = sa_products[2][2];

  wire signed [SUM_W-1:0] at_sum_out;
  wire                     at_valid_out;

  wire [PIXEL_W-1:0] norm_pixel_out;
  wire               norm_valid_out;

  wire obuf_row_ready;
  wire obuf_buf_empty;

  wire row_cnt_ge2;
  assign row_cnt_ge2 = (pic_row_cnt >= 2);
  assign done = (cu_state == 3'd0) && !start;

  pixel_input_controller #(
    .PIXEL_W     (PIXEL_W),
    .IMAGE_WIDTH (IMAGE_WIDTH),
    .IMAGE_HEIGHT(IMAGE_HEIGHT)
  ) u_pic (
    .clk        (clk),        .rst        (rst),
    .pixel_in   (pixel_in),   .pixel_valid(pixel_valid),
    .pixel_ready(pixel_ready),
    .wr_addr    (pic_wr_addr),.wr_data    (pic_wr_data),
    .wr_en_lb0  (pic_wr_en_lb0), .wr_en_lb1(pic_wr_en_lb1),
    .live_pixel (pic_live_pixel), .live_valid(pic_live_valid),
    .row_done   (pic_row_done),  .frame_done(pic_frame_done),
    .row_cnt    (pic_row_cnt)
  );

  line_buffer #(.PIXEL_W(PIXEL_W), .IMAGE_WIDTH(IMAGE_WIDTH)) u_lb0 (
    .clk    (clk),
    .wr_en  (pic_wr_en_lb0), .wr_addr(pic_wr_addr), .wr_data(pic_wr_data),
    .rd_addr(cu_lb_rd_addr), .rd_data(lb0_rd_data)
  );

  line_buffer #(.PIXEL_W(PIXEL_W), .IMAGE_WIDTH(IMAGE_WIDTH)) u_lb1 (
    .clk    (clk),
    .wr_en  (pic_wr_en_lb1), .wr_addr(pic_wr_addr), .wr_data(pic_wr_data),
    .rd_addr(cu_lb_rd_addr), .rd_data(lb1_rd_data)
  );

  sliding_window #(.PIXEL_W(PIXEL_W), .IMAGE_WIDTH(IMAGE_WIDTH)) u_sw (
    .clk        (clk),
    .rst        (rst || cu_sw_flush),
    .shift_en   (cu_shift_en),
    .row0_pixel (lb0_rd_data), .row1_pixel(lb1_rd_data), .row2_pixel(pic_live_pixel),
    .w00(sw_w00),.w01(sw_w01),.w02(sw_w02),
    .w10(sw_w10),.w11(sw_w11),.w12(sw_w12),
    .w20(sw_w20),.w21(sw_w21),.w22(sw_w22),
    .window_valid(sw_window_valid)
  );

  weight_rom #(.WEIGHT_W(WEIGHT_W)) u_wrom (
    .mode(mode),
    .w0(wr_w0),.w1(wr_w1),.w2(wr_w2),
    .w3(wr_w3),.w4(wr_w4),.w5(wr_w5),
    .w6(wr_w6),.w7(wr_w7),.w8(wr_w8)
  );

  systolic_array_3x3 #(
    .PIXEL_W  (PIXEL_W),
    .WEIGHT_W (WEIGHT_W),
    .PRODUCT_W(PRODUCT_W),
    .ROWS     (SA_ROWS),
    .COLS     (SA_COLS)
  ) u_sa (
    .clk           (clk), .rst(rst),
    .load_weight   (cu_load_weight),
    .pixel_valid   (cu_pe_pixel_valid),
    .pixels        (sa_pixels),
    .weights       (sa_weights),
    .products      (sa_products),
    .products_valid(sa_products_valid)
  );

  adder_tree #(.PRODUCT_W(PRODUCT_W), .SUM_W(SUM_W)) u_at (
    .clk      (clk), .rst(rst),
    .p0(at_p0),.p1(at_p1),.p2(at_p2),
    .p3(at_p3),.p4(at_p4),.p5(at_p5),
    .p6(at_p6),.p7(at_p7),.p8(at_p8),
    .valid_in (sa_products_valid),
    .sum_out  (at_sum_out),
    .valid_out(at_valid_out)
  );

  output_normalizer #(.SUM_W(SUM_W), .PIXEL_W(PIXEL_W)) u_norm (
    .raw_result(at_sum_out), .mode(mode),
    .valid_in  (at_valid_out),
    .pixel_out (norm_pixel_out),
    .valid_out (norm_valid_out)
  );

  output_buffer #(.PIXEL_W(PIXEL_W), .OUTPUT_WIDTH(OUTPUT_SIZE)) u_obuf (
    .clk      (clk), .rst(rst),
    .wr_en    (norm_valid_out), .wr_data(norm_pixel_out),
    .rd_en    (cu_out_rd_en),
    .rd_data  (pixel_out),
    .rd_valid (pixel_out_valid),
    .row_ready(obuf_row_ready),
    .buf_empty(obuf_buf_empty)
  );

  control_unit #(
    .IMAGE_WIDTH  (IMAGE_WIDTH),
    .IMAGE_HEIGHT (IMAGE_HEIGHT),
    .OUTPUT_WIDTH (OUTPUT_SIZE),
    .ADDER_LATENCY(ADDER_LATENCY)
  ) u_cu (
    .clk           (clk), .rst(rst),
    .start         (start),
    .window_valid  (sw_window_valid),
    .row_done_in   (pic_row_done),
    .frame_done_in (pic_frame_done),
    .row_cnt_ge2   (row_cnt_ge2),
    .buf_row_ready (obuf_row_ready),
    .buf_empty     (obuf_buf_empty),
    .load_weight   (cu_load_weight),
    .shift_en      (cu_shift_en),
    .sw_flush      (cu_sw_flush),
    .pe_pixel_valid(cu_pe_pixel_valid),
    .out_wr_en     (cu_out_wr_en),
    .out_rd_en     (cu_out_rd_en),
    .lb_rd_addr    (cu_lb_rd_addr),
    .state_out     (cu_state)
  );

endmodule
