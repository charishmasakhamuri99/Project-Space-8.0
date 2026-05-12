module line_buffer #(
  parameter PIXEL_W     = 8,
  parameter IMAGE_WIDTH = 258
)(
  input  wire                              clk,
  input  wire                              wr_en,
  input  wire [$clog2(IMAGE_WIDTH)-1:0]   wr_addr,
  input  wire [PIXEL_W-1:0]               wr_data,
  input  wire [$clog2(IMAGE_WIDTH)-1:0]   rd_addr,
  output reg  [PIXEL_W-1:0]               rd_data
);

  reg [PIXEL_W-1:0] mem [IMAGE_WIDTH-1:0];

  integer i;
  initial begin
    for (i = 0; i < IMAGE_WIDTH; i = i + 1)
      mem[i] = {PIXEL_W{1'b0}};
  end

  always @(posedge clk) begin
    if (wr_en)
      mem[wr_addr] <= wr_data;
  end

  always @(posedge clk) begin
    rd_data <= mem[rd_addr];
  end

endmodule
