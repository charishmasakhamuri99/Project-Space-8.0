`define IMAGE_WIDTH   258
`define IMAGE_HEIGHT  258
`define OUTPUT_WIDTH  256
`define ADDER_LATENCY 4

// Main FSM controller
// States: IDLE -> LOAD_W -> FILL_LB -> FILL_WIN -> COMPUTE -> ROW_DONE -> FRAME_DONE

module control_unit(
  input  clk, rst,
  input  start,
  input  window_valid,
  input  row_done_in,
  input  frame_done_in,
  input  row_cnt_ge2,
  input  buf_row_ready,
  input  buf_empty,
  output reg load_weight,
  output reg shift_en,
  output reg sw_flush,
  output reg pe_pixel_valid,
  output reg out_wr_en,
  output reg out_rd_en,
  output reg [$clog2(`IMAGE_WIDTH)-1:0] lb_rd_addr,
  output reg [2:0] state_out
);

  // State encoding
  localparam S_IDLE       = 3'd0;
  localparam S_LOAD_W     = 3'd1;
  localparam S_FILL_LB    = 3'd2;
  localparam S_FILL_WIN   = 3'd3;
  localparam S_COMPUTE    = 3'd4;
  localparam S_ROW_DONE   = 3'd5;
  localparam S_FRAME_DONE = 3'd6;

  reg [2:0] state, next_state;
  reg [$clog2(`IMAGE_WIDTH)-1:0]  compute_col;
  reg [$clog2(`IMAGE_HEIGHT)-1:0] compute_row;
  reg [`ADDER_LATENCY-1:0] valid_pipe;

  // State register
  always@(posedge clk or negedge rst) begin
    if(!rst) state <= S_IDLE;
    else     state <= next_state;
  end

  // Next-state logic
  always@(*) begin
    next_state = state;
    case(state)
      S_IDLE      : if(start)         next_state = S_LOAD_W;
      S_LOAD_W    :                    next_state = S_FILL_LB;
      S_FILL_LB   : if(row_cnt_ge2)   next_state = S_FILL_WIN;
      S_FILL_WIN  : if(window_valid)   next_state = S_COMPUTE;
      S_COMPUTE   : if(compute_col == `OUTPUT_WIDTH-1)
                                        next_state = S_ROW_DONE;
      S_ROW_DONE  : if(buf_empty) begin
                      if(compute_row == `OUTPUT_WIDTH-1)
                        next_state = S_FRAME_DONE;
                      else
                        next_state = S_FILL_WIN;
                    end
      S_FRAME_DONE:                    next_state = S_IDLE;
      default     :                    next_state = S_IDLE;
    endcase
  end

  // Output logic + counters
  always@(posedge clk or negedge rst) begin
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
      state_out      <= S_IDLE;
    end
    else begin
      // Default deassert
      load_weight    <= 1'b0;
      shift_en       <= 1'b0;
      sw_flush       <= 1'b0;
      pe_pixel_valid <= 1'b0;
      out_rd_en      <= 1'b0;
      state_out      <= state;

      // Delay out_wr_en by ADDER_LATENCY cycles
      valid_pipe <= {valid_pipe[`ADDER_LATENCY-2:0], pe_pixel_valid};
      out_wr_en  <= valid_pipe[`ADDER_LATENCY-1];

      case(state)
        S_IDLE: begin
          compute_col <= 0;
          compute_row <= 0;
          lb_rd_addr  <= 0;
        end

        S_LOAD_W:
          load_weight <= 1'b1;

        S_FILL_LB: begin
          // Wait for row_cnt_ge2 — pixel_input_controller handles LB writes
        end

        S_FILL_WIN: begin
          shift_en   <= 1'b1;
          lb_rd_addr <= compute_col;   // pre-read for sync latency
        end

        S_COMPUTE: begin
          shift_en       <= 1'b1;
          pe_pixel_valid <= window_valid;
          lb_rd_addr     <= compute_col + 1;   // one cycle ahead

          if(compute_col == `OUTPUT_WIDTH-1)
            compute_col <= 0;
          else
            compute_col <= compute_col + 1;
        end

        S_ROW_DONE: begin
          out_rd_en <= ~buf_empty;
          sw_flush  <= 1'b1;

          if(buf_empty) begin
            if(compute_row < `OUTPUT_WIDTH-1)
              compute_row <= compute_row + 1;
            lb_rd_addr  <= 0;
            compute_col <= 0;
          end
        end

        S_FRAME_DONE: begin
          // All done — return to IDLE next cycle
        end
      endcase
    end
  end

endmodule
