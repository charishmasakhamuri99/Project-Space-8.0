module pe #(
    parameter PIXEL = 8,
    parameter WEIGHT = 8,
    parameter PRODUCT = 24
)(
    input  logic clk, rst, load_weight,
    input  logic [WEIGHT-1:0]  weight_in,
    input  logic [PIXEL-1:0]   pixel_in,
    input  logic               pixel_valid,
    output logic signed [PRODUCT-1:0] product_out,
    output logic               out_valid
);

    logic signed [WEIGHT-1:0] weight_reg;

    always_ff @(posedge clk or negedge rst) begin
        if(!rst)
            weight_reg <= {WEIGHT{1'b0}};
        else if(load_weight)
            weight_reg <= weight_in;
    end

    always_ff @(posedge clk or negedge rst) begin
        if(!rst) begin
            product_out <= {PRODUCT{1'b0}};
            out_valid   <= 1'b0;
        end
        else begin
            out_valid <= pixel_valid;
            if(pixel_valid)
                product_out <= {{8{weight_reg[WEIGHT-1]}}, weight_reg} * {{16{1'b0}}, pixel_in};
            else
                product_out <= {PRODUCT{1'b0}};
        end
    end
endmodule
