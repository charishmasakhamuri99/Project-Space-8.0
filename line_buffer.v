`define PIXEL       8
`define IMAGE_WIDTH 258   // 256 + 2 zero-pad columns

// Single row SRAM — 258 x 8-bit
// Write port: synchronous, qualified by wr_en
// Read port : synchronous — rd_data valid one cycle after rd_addr

module line_buffer(
  input  clk,
  input  wr_en,
  input  [$clog2(`IMAGE_WIDTH)-1:0] wr_addr,
  input  [`PIXEL-1:0]               wr_data,
  input  [$clog2(`IMAGE_WIDTH)-1:0] rd_addr,
  output reg [`PIXEL-1:0]           rd_data
);

  reg [`PIXEL-1:0] mem[`IMAGE_WIDTH-1:0];

  integer i;
  initial begin
    for(i=0; i<`IMAGE_WIDTH; i=i+1)
      mem[i] = 8'h00;
  end

  // Synchronous write
  always@(posedge clk) begin
    if(wr_en)
      mem[wr_addr] <= wr_data;
  end

  // Synchronous read
  always@(posedge clk) begin
    rd_data <= mem[rd_addr];
  end

endmodule
