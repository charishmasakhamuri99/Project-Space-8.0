module pixel_input_controller #(
  parameter PIXEL_W      = 8,
  parameter IMAGE_WIDTH  = 258,
  parameter IMAGE_HEIGHT = 258
)(
  input  wire                               clk,
  input  wire                               rst,
  input  wire [PIXEL_W-1:0]                 pixel_in,
  input  wire                               pixel_valid,
  output reg                                pixel_ready,
  output reg  [$clog2(IMAGE_WIDTH)-1:0]     wr_addr,
  output reg  [PIXEL_W-1:0]                 wr_data,
  output reg                                wr_en_lb0,
  output reg                                wr_en_lb1,
  output reg  [PIXEL_W-1:0]                 live_pixel,
  output reg                                live_valid,
  output reg                                row_done,
  output reg                                frame_done,
  output reg  [$clog2(IMAGE_HEIGHT)-1:0]    row_cnt
);

  reg [$clog2(IMAGE_WIDTH)-1:0] col_cnt;
  reg                            lb_wr_sel;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      col_cnt     <= '0;
      row_cnt     <= '0;
      lb_wr_sel   <= 1'b0;
      wr_addr     <= '0;
      wr_data     <= {PIXEL_W{1'b0}};
      wr_en_lb0   <= 1'b0;
      wr_en_lb1   <= 1'b0;
      live_pixel  <= {PIXEL_W{1'b0}};
      live_valid  <= 1'b0;
      row_done    <= 1'b0;
      frame_done  <= 1'b0;
      pixel_ready <= 1'b1;
    end else begin
      row_done    <= 1'b0;
      frame_done  <= 1'b0;
      wr_en_lb0   <= 1'b0;
      wr_en_lb1   <= 1'b0;
      live_valid  <= 1'b0;
      pixel_ready <= 1'b1;

      if (pixel_valid && pixel_ready) begin
        wr_addr    <= col_cnt;
        wr_data    <= pixel_in;
        live_pixel <= pixel_in;
        live_valid <= 1'b1;

        if (row_cnt == 0)
          wr_en_lb0 <= 1'b1;
        else if (row_cnt == 1)
          wr_en_lb1 <= 1'b1;
        else begin
          if (lb_wr_sel == 1'b0)
            wr_en_lb0 <= 1'b1;
          else
            wr_en_lb1 <= 1'b1;
        end

        if (col_cnt == IMAGE_WIDTH-1) begin
          col_cnt  <= '0;
          row_done <= 1'b1;

          if (row_cnt >= 2)
            lb_wr_sel <= ~lb_wr_sel;

          if (row_cnt == IMAGE_HEIGHT-1) begin
            row_cnt    <= '0;
            frame_done <= 1'b1;
          end else
            row_cnt <= row_cnt + 1'b1;
        end else
          col_cnt <= col_cnt + 1'b1;
      end
    end
  end

endmodule
