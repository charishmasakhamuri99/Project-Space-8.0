module top #(
    parameter PIXEL = 8,
    parameter WEIGHT = 8,
    parameter PRODUCT = 24,
    parameter SUM = 27,
    parameter IMAGE_WIDTH = 258,
    parameter IMAGE_HEIGHT = 258,
    parameter OUTPUT_SIZE = 256
)(
    input  logic clk, rst, start, mode,
    input  logic [7:0] pixel_in,
    input  logic pixel_valid,
    output logic pixel_ready,
    output logic [7:0] pixel_out,
    output logic pixel_out_valid,
    output logic done
);

    logic [$clog2(IMAGE_WIDTH)-1:0]  pic_wr_addr;
    logic [7:0] pic_wr_data, pic_live_pixel;
    logic pic_wr_en_lb0, pic_wr_en_lb1, pic_live_valid, pic_row_done, pic_frame_done;
    logic [$clog2(IMAGE_HEIGHT)-1:0] pic_row_cnt;
    logic [7:0] lb0_rd_data, lb1_rd_data;
    logic cu_load_weight, cu_shift_en, cu_sw_flush, cu_pe_pixel_valid, cu_out_wr_en, cu_out_rd_en;
    logic [$clog2(IMAGE_WIDTH)-1:0] cu_lb_rd_addr;
    logic [2:0] cu_state;
    logic [7:0] sw_w00, sw_w01, sw_w02, sw_w10, sw_w11, sw_w12, sw_w20, sw_w21, sw_w22;
    logic sw_window_valid;
    logic signed [7:0] wr_w0, wr_w1, wr_w2, wr_w3, wr_w4, wr_w5, wr_w6, wr_w7, wr_w8;
    logic signed [23:0] sa_p0, sa_p1, sa_p2, sa_p3, sa_p4, sa_p5, sa_p6, sa_p7, sa_p8;
    logic sa_products_valid, at_valid_out, norm_valid_out, obuf_row_ready, obuf_buf_empty;
    logic signed [26:0] at_sum_out;
    logic [7:0] norm_pixel_out;

    assign done = (cu_state == 3'd0) && !start;

    pixel_input_controller #(PIXEL, IMAGE_WIDTH, IMAGE_HEIGHT) u_pic (
        clk, rst, pixel_in, pixel_valid, pixel_ready, pic_wr_addr, pic_wr_data,
        pic_wr_en_lb0, pic_wr_en_lb1, pic_live_pixel, pic_live_valid, pic_row_done, pic_frame_done, pic_row_cnt
    );

    line_buffer #(PIXEL, IMAGE_WIDTH) u_lb0 (clk, pic_wr_en_lb0, pic_wr_addr, pic_wr_data, cu_lb_rd_addr, lb0_rd_data);
    line_buffer #(PIXEL, IMAGE_WIDTH) u_lb1 (clk, pic_wr_en_lb1, pic_wr_addr, pic_wr_data, cu_lb_rd_addr, lb1_rd_data);

    sliding_window #(PIXEL) u_sw (clk, (rst || cu_sw_flush), cu_shift_en, lb0_rd_data, lb1_rd_data, pic_live_pixel, 
        sw_w00, sw_w01, sw_w02, sw_w10, sw_w11, sw_w12, sw_w20, sw_w21, sw_w22, sw_window_valid);

    weight_rom u_wrom (mode, wr_w0, wr_w1, wr_w2, wr_w3, wr_w4, wr_w5, wr_w6, wr_w7, wr_w8);

    systolic_array_3x3 #(PIXEL, WEIGHT, PRODUCT) u_sa (clk, rst, cu_load_weight, cu_pe_pixel_valid,
        sw_w00, sw_w01, sw_w02, sw_w10, sw_w11, sw_w12, sw_w20, sw_w21, sw_w22,
        wr_w0, wr_w1, wr_w2, wr_w3, wr_w4, wr_w5, wr_w6, wr_w7, wr_w8,
        sa_p0, sa_p1, sa_p2, sa_p3, sa_p4, sa_p5, sa_p6, sa_p7, sa_p8, sa_products_valid);

    adder_tree #(PRODUCT, SUM) u_at (clk, rst, sa_p0, sa_p1, sa_p2, sa_p3, sa_p4, sa_p5, sa_p6, sa_p7, sa_p8, sa_products_valid, at_sum_out, at_valid_out);

    output_normalizer #(SUM, PIXEL) u_norm (at_sum_out, mode, at_valid_out, norm_pixel_out, norm_valid_out);

    output_buffer #(PIXEL, OUTPUT_SIZE) u_obuf (clk, rst, norm_valid_out, norm_pixel_out, cu_out_rd_en, pixel_out, pixel_out_valid, obuf_row_ready, obuf_buf_empty);

    control_unit #(IMAGE_WIDTH, IMAGE_HEIGHT, OUTPUT_SIZE, 4) u_cu (
        clk, rst, start, sw_window_valid, pic_row_done, pic_frame_done, (pic_row_cnt >= 2), obuf_row_ready, obuf_buf_empty,
        cu_load_weight, cu_shift_en, cu_sw_flush, cu_pe_pixel_valid, cu_out_wr_en, cu_out_rd_en, cu_lb_rd_addr, cu_state
    );
endmodule
