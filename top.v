`define IMAGE_WIDTH  258
`define IMAGE_HEIGHT 258
`define OUTPUT_SIZE  256

`timescale 1ns/1ps

// Top-level: connects all submodules into the complete pipeline
// pixel_in -> pixel_input_controller -> line_buffer_0/1 -> sliding_window
//          -> systolic_array_3x3 -> adder_tree -> output_normalizer -> output_buffer

module top(
  input  clk, rst, start,
  input  mode,               // 0=Gaussian, 1=Sobel-X
  input  [7:0] pixel_in,
  input  pixel_valid,
  output wire pixel_ready,
  output wire [7:0] pixel_out,
  output wire pixel_out_valid,
  output wire done
);

  // pixel_input_controller wires
  wire [$clog2(`IMAGE_WIDTH)-1:0]  pic_wr_addr;
  wire [7:0]  pic_wr_data;
  wire        pic_wr_en_lb0, pic_wr_en_lb1;
  wire [7:0]  pic_live_pixel;
  wire        pic_live_valid;
  wire        pic_row_done, pic_frame_done;
  wire [$clog2(`IMAGE_HEIGHT)-1:0] pic_row_cnt;

  // line_buffer wires
  wire [7:0]  lb0_rd_data, lb1_rd_data;

  // control_unit wires
  wire        cu_load_weight;
  wire        cu_shift_en;
  wire        cu_sw_flush;
  wire        cu_pe_pixel_valid;
  wire        cu_out_wr_en;
  wire        cu_out_rd_en;
  wire [$clog2(`IMAGE_WIDTH)-1:0] cu_lb_rd_addr;
  wire [2:0]  cu_state;

  // sliding_window wires
  wire [7:0]  sw_w00,sw_w01,sw_w02;
  wire [7:0]  sw_w10,sw_w11,sw_w12;
  wire [7:0]  sw_w20,sw_w21,sw_w22;
  wire        sw_window_valid;

  // weight_rom wires
  wire signed [7:0] wr_w0,wr_w1,wr_w2;
  wire signed [7:0] wr_w3,wr_w4,wr_w5;
  wire signed [7:0] wr_w6,wr_w7,wr_w8;

  // systolic array wires
  wire signed [23:0] sa_p0,sa_p1,sa_p2;
  wire signed [23:0] sa_p3,sa_p4,sa_p5;
  wire signed [23:0] sa_p6,sa_p7,sa_p8;
  wire        sa_products_valid;

  // adder tree wires
  wire signed [26:0] at_sum_out;
  wire        at_valid_out;

  // normalizer wires
  wire [7:0]  norm_pixel_out;
  wire        norm_valid_out;

  // output buffer wires
  wire        obuf_row_ready;
  wire        obuf_buf_empty;

  wire row_cnt_ge2;
  assign row_cnt_ge2 = (pic_row_cnt >= 2);

  assign done = (cu_state == 3'd0) && !start;

  // 1. Pixel Input Controller
  pixel_input_controller u_pic(
    .clk        (clk),
    .rst        (rst),
    .pixel_in   (pixel_in),
    .pixel_valid(pixel_valid),
    .pixel_ready(pixel_ready),
    .wr_addr    (pic_wr_addr),
    .wr_data    (pic_wr_data),
    .wr_en_lb0  (pic_wr_en_lb0),
    .wr_en_lb1  (pic_wr_en_lb1),
    .live_pixel (pic_live_pixel),
    .live_valid (pic_live_valid),
    .row_done   (pic_row_done),
    .frame_done (pic_frame_done),
    .row_cnt    (pic_row_cnt)
  );

  // 2. Line Buffer 0 (holds row N-2)
  line_buffer u_lb0(
    .clk    (clk),
    .wr_en  (pic_wr_en_lb0),
    .wr_addr(pic_wr_addr),
    .wr_data(pic_wr_data),
    .rd_addr(cu_lb_rd_addr),
    .rd_data(lb0_rd_data)
  );

  // 3. Line Buffer 1 (holds row N-1)
  line_buffer u_lb1(
    .clk    (clk),
    .wr_en  (pic_wr_en_lb1),
    .wr_addr(pic_wr_addr),
    .wr_data(pic_wr_data),
    .rd_addr(cu_lb_rd_addr),
    .rd_data(lb1_rd_data)
  );

  // 4. Sliding Window (rst OR sw_flush resets fill counter between rows)
  sliding_window u_sw(
    .clk        (clk),
    .rst        (rst || cu_sw_flush),
    .shift_en   (cu_shift_en),
    .row0_pixel (lb0_rd_data),
    .row1_pixel (lb1_rd_data),
    .row2_pixel (pic_live_pixel),
    .w00(sw_w00),.w01(sw_w01),.w02(sw_w02),
    .w10(sw_w10),.w11(sw_w11),.w12(sw_w12),
    .w20(sw_w20),.w21(sw_w21),.w22(sw_w22),
    .window_valid(sw_window_valid)
  );

  // 5. Weight ROM
  weight_rom u_wrom(
    .mode(mode),
    .w0(wr_w0),.w1(wr_w1),.w2(wr_w2),
    .w3(wr_w3),.w4(wr_w4),.w5(wr_w5),
    .w6(wr_w6),.w7(wr_w7),.w8(wr_w8)
  );

  // 6. Systolic Array 3x3
  systolic_array_3x3 u_sa(
    .clk        (clk),
    .rst        (rst),
    .load_weight(cu_load_weight),
    .pixel_valid(cu_pe_pixel_valid),
    .w00(sw_w00),.w01(sw_w01),.w02(sw_w02),
    .w10(sw_w10),.w11(sw_w11),.w12(sw_w12),
    .w20(sw_w20),.w21(sw_w21),.w22(sw_w22),
    .wt0(wr_w0),.wt1(wr_w1),.wt2(wr_w2),
    .wt3(wr_w3),.wt4(wr_w4),.wt5(wr_w5),
    .wt6(wr_w6),.wt7(wr_w7),.wt8(wr_w8),
    .p0(sa_p0),.p1(sa_p1),.p2(sa_p2),
    .p3(sa_p3),.p4(sa_p4),.p5(sa_p5),
    .p6(sa_p6),.p7(sa_p7),.p8(sa_p8),
    .products_valid(sa_products_valid)
  );

  // 7. Adder Tree
  adder_tree u_at(
    .clk      (clk),
    .rst      (rst),
    .p0(sa_p0),.p1(sa_p1),.p2(sa_p2),
    .p3(sa_p3),.p4(sa_p4),.p5(sa_p5),
    .p6(sa_p6),.p7(sa_p7),.p8(sa_p8),
    .valid_in (sa_products_valid),
    .sum_out  (at_sum_out),
    .valid_out(at_valid_out)
  );

  // 8. Output Normalizer
  output_normalizer u_norm(
    .raw_result(at_sum_out),
    .mode      (mode),
    .valid_in  (at_valid_out),
    .pixel_out (norm_pixel_out),
    .valid_out (norm_valid_out)
  );

  // 9. Output Buffer
  output_buffer u_obuf(
    .clk      (clk),
    .rst      (rst),
    .wr_en    (norm_valid_out),
    .wr_data  (norm_pixel_out),
    .rd_en    (cu_out_rd_en),
    .rd_data  (pixel_out),
    .rd_valid (pixel_out_valid),
    .row_ready(obuf_row_ready),
    .buf_empty(obuf_buf_empty)
  );

  // 10. Control Unit FSM
  control_unit u_cu(
    .clk           (clk),
    .rst           (rst),
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
