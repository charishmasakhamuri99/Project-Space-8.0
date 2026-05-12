module control_unit #(
    parameter IMAGE_WIDTH = 258,
    parameter IMAGE_HEIGHT = 258,
    parameter OUTPUT_WIDTH = 256,
    parameter ADDER_LATENCY = 4
)(
    input  logic clk, rst,
    input  logic start,
    input  logic window_valid,
    input  logic row_done_in,
    input  logic frame_done_in,
    input  logic row_cnt_ge2,
    input  logic buf_row_ready,
    input  logic buf_empty,
    output logic load_weight,
    output logic shift_en,
    output logic sw_flush,
    output logic pe_pixel_valid,
    output logic out_wr_en,
    output logic out_rd_en,
    output logic [$clog2(IMAGE_WIDTH)-1:0] lb_rd_addr,
    output logic [2:0] state_out
);

    typedef enum logic [2:0] {
        S_IDLE       = 3'd0,
        S_LOAD_W     = 3'd1,
        S_FILL_LB    = 3'd2,
        S_FILL_WIN   = 3'd3,
        S_COMPUTE    = 3'd4,
        S_ROW_DONE   = 3'd5,
        S_FRAME_DONE = 3'd6
    } state_t;

    state_t state, next_state;
    logic [$clog2(IMAGE_WIDTH)-1:0]  compute_col;
    logic [$clog2(IMAGE_HEIGHT)-1:0] compute_row;
    logic [ADDER_LATENCY-1:0]        valid_pipe;

    always_ff @(posedge clk or negedge rst) begin
        if(!rst) state <= S_IDLE;
        else     state <= next_state;
    end

    always_comb begin
        next_state = state;
        case(state)
            S_IDLE      : if(start)         next_state = S_LOAD_W;
            S_LOAD_W    :                   next_state = S_FILL_LB;
            S_FILL_LB   : if(row_cnt_ge2)   next_state = S_FILL_WIN;
            S_FILL_WIN  : if(window_valid)  next_state = S_COMPUTE;
            S_COMPUTE   : if(compute_col == OUTPUT_WIDTH-1)
                                            next_state = S_ROW_DONE;
            S_ROW_DONE  : if(buf_empty) begin
                             if(compute_row == OUTPUT_WIDTH-1)
                               next_state = S_FRAME_DONE;
                             else
                               next_state = S_FILL_WIN;
                          end
            S_FRAME_DONE:                   next_state = S_IDLE;
            default     :                   next_state = S_IDLE;
        endcase
    end

    always_ff @(posedge clk or negedge rst) begin
        if(!rst) begin
            load_weight    <= 1'b0;
            shift_en       <= 1'b0;
            sw_flush       <= 1'b0;
            pe_pixel_valid <= 1'b0;
            out_wr_en      <= 1'b0;
            out_rd_en      <= 1'b0;
            lb_rd_addr     <= 0;
            compute_col    <= 0;
            compute_row    <= 0;
            valid_pipe     <= 0;
            state_out      <= 3'd0;
        end
        else begin
            load_weight    <= 1'b0;
            shift_en       <= 1'b0;
            sw_flush       <= 1'b0;
            pe_pixel_valid <= 1'b0;
            out_rd_en      <= 1'b0;
            state_out      <= logic'(state);

            valid_pipe <= {valid_pipe[ADDER_LATENCY-2:0], pe_pixel_valid};
            out_wr_en  <= valid_pipe[ADDER_LATENCY-1];

            case(state)
                S_IDLE: begin
                    compute_col <= 0;
                    compute_row <= 0;
                    lb_rd_addr  <= 0;
                end
                S_LOAD_W: load_weight <= 1'b1;
                S_FILL_WIN: begin
                    shift_en   <= 1'b1;
                    lb_rd_addr <= compute_col;
                end
                S_COMPUTE: begin
                    shift_en       <= 1'b1;
                    pe_pixel_valid <= window_valid;
                    lb_rd_addr     <= compute_col + 1'b1;
                    if(compute_col == OUTPUT_WIDTH-1)
                        compute_col <= 0;
                    else
                        compute_col <= compute_col + 1'b1;
                end
                S_ROW_DONE: begin
                    out_rd_en <= ~buf_empty;
                    sw_flush  <= 1'b1;
                    if(buf_empty) begin
                        if(compute_row < OUTPUT_WIDTH-1)
                            compute_row <= compute_row + 1'b1;
                        lb_rd_addr  <= 0;
                        compute_col <= 0;
                    end
                end
            endcase
        end
    end
endmodule
