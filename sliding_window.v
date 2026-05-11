module sliding_window #(
    parameter PIXEL = 8
)(
    input  logic clk, rst,
    input  logic shift_en,
    input  logic [PIXEL-1:0] row0_pixel,
    input  logic [PIXEL-1:0] row1_pixel,
    input  logic [PIXEL-1:0] row2_pixel,
    output logic [PIXEL-1:0] w00, w01, w02,
    output logic [PIXEL-1:0] w10, w11, w12,
    output logic [PIXEL-1:0] w20, w21, w22,
    output logic             window_valid
);

    logic [PIXEL-1:0] r0a, r0b, r0c;
    logic [PIXEL-1:0] r1a, r1b, r1c;
    logic [PIXEL-1:0] r2a, r2b, r2c;
    logic [1:0] fill_cnt;

    always_ff @(posedge clk or negedge rst) begin
        if(!rst) begin
            r0a<='0; r0b<='0; r0c<='0;
            r1a<='0; r1b<='0; r1c<='0;
            r2a<='0; r2b<='0; r2c<='0;
            fill_cnt     <= 2'd0;
            window_valid <= 1'b0;
        end
        else if(shift_en) begin
            r0c <= r0b; r0b <= r0a; r0a <= row0_pixel;
            r1c <= r1b; r1b <= r1a; r1a <= row1_pixel;
            r2c <= r2b; r2b <= r2a; r2a <= row2_pixel;

            if(fill_cnt < 2'd3) fill_cnt <= fill_cnt + 1'b1;
            if(fill_cnt == 2'd2) window_valid <= 1'b1;
        end
    end

    assign w00=r0c; assign w01=r0b; assign w02=r0a;
    assign w10=r1c; assign w11=r1b; assign w12=r1a;
    assign w20=r2c; assign w21=r2b; assign w22=r2a;
endmodule
