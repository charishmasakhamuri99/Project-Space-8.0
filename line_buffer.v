module line_buffer #(
    parameter PIXEL = 8,
    parameter IMAGE_WIDTH = 258
)(
    input  logic clk,
    input  logic wr_en,
    input  logic [$clog2(IMAGE_WIDTH)-1:0] wr_addr,
    input  logic [PIXEL-1:0]               wr_data,
    input  logic [$clog2(IMAGE_WIDTH)-1:0] rd_addr,
    output logic [PIXEL-1:0]               rd_data
);

    logic [PIXEL-1:0] mem[IMAGE_WIDTH-1:0];

    initial begin
        for(int i=0; i<IMAGE_WIDTH; i++)
            mem[i] = {PIXEL{1'b0}};
    end

    always_ff @(posedge clk) begin
        if(wr_en)
            mem[wr_addr] <= wr_data;
    end

    always_ff @(posedge clk) begin
        rd_data <= mem[rd_addr];
    end
endmodule
