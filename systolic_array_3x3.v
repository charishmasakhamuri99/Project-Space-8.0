module systolic_array_3x3 #(
  parameter PIXEL_W   = 8,
  parameter WEIGHT_W  = 8,
  parameter PRODUCT_W = 24,
  parameter ROWS      = 3,
  parameter COLS      = 3
)(
  input  wire                        clk,
  input  wire                        rst,
  input  wire                        load_weight,
  input  wire                        pixel_valid,
  input  wire [PIXEL_W-1:0]          pixels  [ROWS-1:0][COLS-1:0],
  input  wire signed [WEIGHT_W-1:0]  weights [ROWS-1:0][COLS-1:0],
  output wire signed [PRODUCT_W-1:0] products[ROWS-1:0][COLS-1:0],
  output wire                        products_valid
);

  localparam N = ROWS * COLS;

  wire [N-1:0] pe_valid_flat;
  assign products_valid = pe_valid_flat[0];

  genvar r, c;
  generate
    for (r = 0; r < ROWS; r = r + 1) begin : gen_row
      for (c = 0; c < COLS; c = c + 1) begin : gen_col
        pe #(
          .WEIGHT_W (WEIGHT_W),
          .PIXEL_W  (PIXEL_W),
          .PRODUCT_W(PRODUCT_W)
        ) u_pe (
          .clk        (clk),
          .rst        (rst),
          .load_weight(load_weight),
          .weight_in  (weights[r][c]),
          .pixel_in   (pixels[r][c]),
          .pixel_valid(pixel_valid),
          .product_out(products[r][c]),
          .out_valid  (pe_valid_flat[r*COLS + c])
        );
      end
    end
  endgenerate

endmodule
