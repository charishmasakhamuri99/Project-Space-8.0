module output_buffer #(
    parameter PIXEL = 8,
    parameter OUTPUT_WIDTH = 256
)(
    input  logic clk, rst,
    input  logic wr_en,
    input  logic [PIXEL-1:0] wr_data,
    input  logic rd_en,
    output logic [PIXEL-1:0] rd_data,
    output logic rd_valid,
    output logic row_ready,
    output logic buf_empty
);

    logic [PIXEL-1:0] mem[OUTPUT_WIDTH-1:0];
    logic [$clog2(OUTPUT_WIDTH)-1:0] wr_ptr;
    logic [$clog2(OUTPUT_WIDTH)-1:0] rd_ptr;

    initial begin
        for(int i=0; i<OUTPUT_WIDTH; i++)
            mem[i] = {PIXEL{1'b0}};
    end

    always_ff @(posedge clk or negedge rst) begin
        if(!rst) begin
            wr_ptr    <= 0;
            row_ready <= 1'b0;
        end
        else begin
            row_ready <= 1'b0;
            if(wr_en) begin
                mem[wr_ptr] <= wr_data;
                if(wr_ptr == OUTPUT_WIDTH-1) begin
                    wr_ptr    <= 0;
                    row_ready <= 1'b1;
                end
                else
                    wr_ptr <= wr_ptr + 1'b1;
            end
        end
    end

    always_ff @(posedge clk or negedge rst) begin
        if(!rst) begin
            rd_ptr    <= 0;
            rd_data   <= {PIXEL{1'b0}};
            rd_valid  <= 1'b0;
            buf_empty <= 1'b1;
        end
        else begin
            rd_valid  <= 1'b0;
            buf_empty <= 1'b0;
            if(rd_en) begin
                rd_data  <= mem[rd_ptr];
                rd_valid <= 1'b1;
                if(rd_ptr == OUTPUT_WIDTH-1) begin
                    rd_ptr    <= 0;
                    buf_empty <= 1'b1;
                end
                else
                    rd_ptr <= rd_ptr + 1'b1;
            end
        end
    end
endmodule
