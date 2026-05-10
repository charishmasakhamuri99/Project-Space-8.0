`define WEIGHT 8

// Combinational ROM — two 3x3 kernels selected by mode
// mode=0 : Gaussian (sum=16, normalizer does >>4)
// mode=1 : Sobel-X

module weight_rom(
  input mode,
  output reg signed [`WEIGHT-1:0] w0, w1, w2,
                                  w3, w4, w5,
                                  w6, w7, w8
);

  always@(*) begin
    case(mode)
      1'b0: begin   // Gaussian: [1 2 1 / 2 4 2 / 1 2 1]
        w0=8'sd1;  w1=8'sd2;  w2=8'sd1;
        w3=8'sd2;  w4=8'sd4;  w5=8'sd2;
        w6=8'sd1;  w7=8'sd2;  w8=8'sd1;
      end
      1'b1: begin   // Sobel-X: [-1 0 +1 / -2 0 +2 / -1 0 +1]
        w0=-8'sd1; w1=8'sd0;  w2=8'sd1;
        w3=-8'sd2; w4=8'sd0;  w5=8'sd2;
        w6=-8'sd1; w7=8'sd0;  w8=8'sd1;
      end
      default: begin
        w0=8'sd0; w1=8'sd0; w2=8'sd0;
        w3=8'sd0; w4=8'sd0; w5=8'sd0;
        w6=8'sd0; w7=8'sd0; w8=8'sd0;
      end
    endcase
  end

endmodule
