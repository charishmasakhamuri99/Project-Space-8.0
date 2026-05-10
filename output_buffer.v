`define PIXEL       8
`define OUTPUT_WIDTH 256

// 256-entry output row buffer
// Write: one pixel per clock from normalizer when wr_en=1
// Read : one pixel per clock when rd_en=1
// row_ready pulses when full row is written; buf_empty pulses when fully read out

module output_buffer(
  input  clk, rst,
  input  wr_en,
  input  [`PIXEL-1:0] wr_data,
  input  rd_en,
  output reg [`PIXEL-1:0] rd_data,
  output reg rd_valid,
  output reg row_ready,
  output reg buf_empty
);

  reg [`PIXEL-1:0] mem[`OUTPUT_WIDTH-1:0];
  reg [$clog2(`OUTPUT_WIDTH)-1:0] wr_ptr;
  reg [$clog2(`OUTPUT_WIDTH)-1:0] rd_ptr;

  integer i;
  initial begin
    for(i=0; i<`OUTPUT_WIDTH; i=i+1)
      mem[i] = 8'h00;
  end

  // Write logic
  always@(posedge clk or negedge rst) begin
    if(!rst) begin
      wr_ptr    <= 0;
      row_ready <= 1'b0;
    end
    else begin
      row_ready <= 1'b0;
      if(wr_en) begin
        mem[wr_ptr] <= wr_data;
        if(wr_ptr == `OUTPUT_WIDTH-1) begin
          wr_ptr    <= 0;
          row_ready <= 1'b1;
        end
        else
          wr_ptr <= wr_ptr + 1;
      end
    end
  end

  // Read logic
  always@(posedge clk or negedge rst) begin
    if(!rst) begin
      rd_ptr   <= 0;
      rd_data  <= 8'h00;
      rd_valid <= 1'b0;
      buf_empty<= 1'b1;
    end
    else begin
      rd_valid  <= 1'b0;
      buf_empty <= 1'b0;
      if(rd_en) begin
        rd_data  <= mem[rd_ptr];
        rd_valid <= 1'b1;
        if(rd_ptr == `OUTPUT_WIDTH-1) begin
          rd_ptr    <= 0;
          buf_empty <= 1'b1;
        end
        else
          rd_ptr <= rd_ptr + 1;
      end
    end
  end

endmodule
