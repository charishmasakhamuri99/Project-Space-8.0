module pixel_input_controller #(
    parameter PIXEL = 8,
    parameter IMAGE_WIDTH = 258,
    parameter IMAGE_HEIGHT = 258
)(
    input  logic clk, rst,
    input  logic [PIXEL-1:0] pixel_in,
    input  logic pixel_valid,
    output logic pixel_ready,
    output logic [$clog2(IMAGE_WIDTH)-1:0]  wr_addr,
    output logic [PIXEL-1:0]                wr_data,
    output logic wr_en_lb0,
    output logic wr_en_lb1,
    output logic [PIXEL-1:0] live_pixel,
    output logic live_valid,
    output logic row_done,
    output logic frame_done,
    output logic [$clog2(IMAGE_HEIGHT)-1:0] row_cnt
);

    logic [$clog2(IMAGE_WIDTH)-1:0] col_cnt;
    logic                           lb_wr_sel;

    always_ff @(posedge clk or negedge rst) begin
        if(!rst) begin
            col_cnt    <= 0;
            row_cnt    <= 0;
            lb_wr_sel  <= 1'b0;
            wr_addr    <= 0;
            wr_data    <= {PIXEL{1'b0}};
            wr_en_lb0  <= 1'b0;
            wr_en_lb1  <= 1'b0;
            live_pixel <= {PIXEL{1'b0}};
            live_valid <= 1'b0;
            row_done   <= 1'b0;
            frame_done <= 1'b0;
            pixel_ready<= 1'b1;
        end
        else begin
            row_done   <= 1'b0;
            frame_done <= 1'b0;
            wr_en_lb0  <= 1'b0;
            wr_en_lb1  <= 1'b0;
            live_valid <= 1'b0;
            pixel_ready<= 1'b1;

            if(pixel_valid && pixel_ready) begin
                wr_addr    <= col_cnt;
                wr_data    <= pixel_in;
                live_pixel <= pixel_in;
                live_valid <= 1'b1;

                if(row_cnt == 0)
                    wr_en_lb0 <= 1'b1;
                else if(row_cnt == 1)
                    wr_en_lb1 <= 1'b1;
                else begin
                    if(lb_wr_sel == 1'b0) wr_en_lb0 <= 1'b1;
                    else                 wr_en_lb1 <= 1'b1;
                end

                if(col_cnt == IMAGE_WIDTH-1) begin
                    col_cnt  <= 0;
                    row_done <= 1'b1;
                    if(row_cnt >= 2) lb_wr_sel <= ~lb_wr_sel;
                    if(row_cnt == IMAGE_HEIGHT-1) begin
                        row_cnt    <= 0;
                        frame_done <= 1'b1;
                    end
                    else row_cnt <= row_cnt + 1'b1;
                end
                else col_cnt <= col_cnt + 1'b1;
            end
        end
    end
endmodule
