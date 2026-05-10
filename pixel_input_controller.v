`define PIXEL        8
`define IMAGE_WIDTH  258
`define IMAGE_HEIGHT 258

// Accepts one pixel per clock; routes to line_buffer_0, line_buffer_1,
// or live path for sliding window. Ping-pong write pointer between the two LBs.
// Row 0 -> LB0, Row 1 -> LB1, Row 2+ -> oldest LB slot (lb_wr_sel toggles)

module pixel_input_controller(
  input  clk, rst,
  input  [`PIXEL-1:0] pixel_in,
  input  pixel_valid,
  output reg pixel_ready,
  output reg [$clog2(`IMAGE_WIDTH)-1:0]  wr_addr,
  output reg [`PIXEL-1:0]                wr_data,
  output reg wr_en_lb0,
  output reg wr_en_lb1,
  output reg [`PIXEL-1:0] live_pixel,
  output reg live_valid,
  output reg row_done,
  output reg frame_done,
  output reg [$clog2(`IMAGE_HEIGHT)-1:0] row_cnt
);

  reg [$clog2(`IMAGE_WIDTH)-1:0]  col_cnt;
  reg                              lb_wr_sel;

  always@(posedge clk or negedge rst) begin
    if(!rst) begin
      col_cnt    <= 0;
      row_cnt    <= 0;
      lb_wr_sel  <= 1'b0;
      wr_addr    <= 0;
      wr_data    <= 8'h00;
      wr_en_lb0  <= 1'b0;
      wr_en_lb1  <= 1'b0;
      live_pixel <= 8'h00;
      live_valid <= 1'b0;
      row_done   <= 1'b0;
      frame_done <= 1'b0;
      pixel_ready<= 1'b1;
    end
    else begin
      // Default de-assert pulsed signals
      row_done   <= 1'b0;
      frame_done <= 1'b0;
      wr_en_lb0  <= 1'b0;
      wr_en_lb1  <= 1'b0;
      live_valid <= 1'b0;
      pixel_ready<= 1'b1;   // no backpressure

      if(pixel_valid && pixel_ready) begin
        wr_addr    <= col_cnt;
        wr_data    <= pixel_in;
        live_pixel <= pixel_in;
        live_valid <= 1'b1;

        // Row 0 -> LB0, Row 1 -> LB1, Row 2+ -> ping-pong
        if(row_cnt == 0)
          wr_en_lb0 <= 1'b1;
        else if(row_cnt == 1)
          wr_en_lb1 <= 1'b1;
        else begin
          if(lb_wr_sel == 1'b0)
            wr_en_lb0 <= 1'b1;
          else
            wr_en_lb1 <= 1'b1;
        end

        // Advance column counter
        if(col_cnt == `IMAGE_WIDTH-1) begin
          col_cnt  <= 0;
          row_done <= 1'b1;

          if(row_cnt >= 2)
            lb_wr_sel <= ~lb_wr_sel;

          if(row_cnt == `IMAGE_HEIGHT-1) begin
            row_cnt    <= 0;
            frame_done <= 1'b1;
          end
          else
            row_cnt <= row_cnt + 1;
        end
        else
          col_cnt <= col_cnt + 1;
      end
    end
  end

endmodule
