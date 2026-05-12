`timescale 1ns/1ps

module tb_top;

  parameter IMAGE_WIDTH   = 258;
  parameter IMAGE_HEIGHT  = 258;
  parameter OUTPUT_SIZE   = 256;
  parameter PIXEL_W       = 8;
  parameter CLK_PERIOD    = 10;
  parameter TOTAL_PIXELS  = IMAGE_WIDTH * IMAGE_HEIGHT;
  parameter TOTAL_OUTPUT  = OUTPUT_SIZE * OUTPUT_SIZE;

  reg        clk, rst, start, mode;
  reg  [7:0] pixel_in;
  reg        pixel_valid;
  wire       pixel_ready;
  wire [7:0] pixel_out;
  wire       pixel_out_valid;
  wire       done;

  integer i, j;
  integer pix_fd, out_fd, ref_fd;
  integer cmp_errors;
  integer out_pixel_count;

  reg [7:0] ref_buf [0:TOTAL_OUTPUT-1];
  reg [7:0] out_buf [0:TOTAL_OUTPUT-1];

  top #(
    .IMAGE_WIDTH  (IMAGE_WIDTH),
    .IMAGE_HEIGHT (IMAGE_HEIGHT),
    .OUTPUT_SIZE  (OUTPUT_SIZE)
  ) dut (
    .clk           (clk),
    .rst           (rst),
    .start         (start),
    .mode          (mode),
    .pixel_in      (pixel_in),
    .pixel_valid   (pixel_valid),
    .pixel_ready   (pixel_ready),
    .pixel_out     (pixel_out),
    .pixel_out_valid(pixel_out_valid),
    .done          (done)
  );

  always #(CLK_PERIOD/2) clk = ~clk;

  task reset_dut;
    begin
      rst         = 1'b0;
      start       = 1'b0;
      pixel_valid = 1'b0;
      pixel_in    = 8'h00;
      @(posedge clk); #1;
      @(posedge clk); #1;
      rst = 1'b1;
      @(posedge clk); #1;
    end
  endtask

  task feed_image(input [255*8:0] pixel.txt);
    integer fd;
    integer pixel_val;
    integer col, row;
    begin
      fd = $fopen(filename, "rb");
      if (fd == 0) begin
        $display("ERROR: Cannot open pixel file: %s", filename);
        $finish;
      end
      for (row = 0; row < IMAGE_HEIGHT; row = row + 1) begin
        for (col = 0; col < IMAGE_WIDTH; col = col + 1) begin
          pixel_val = $fgetc(fd);
          if (pixel_val < 0) begin
            $display("ERROR: Unexpected EOF at row=%0d col=%0d", row, col);
            $fclose(fd);
            $finish;
          end
          @(posedge clk);
          while (!pixel_ready) @(posedge clk);
          #1;
          pixel_in    = pixel_val[7:0];
          pixel_valid = 1'b1;
        end
      end
      @(posedge clk); #1;
      pixel_valid = 1'b0;
      $fclose(fd);
    end
  endtask

  task collect_output;
    begin
      out_pixel_count = 0;
      while (out_pixel_count < TOTAL_OUTPUT) begin
        @(posedge clk);
        if (pixel_out_valid) begin
          out_buf[out_pixel_count] = pixel_out;
          out_pixel_count = out_pixel_count + 1;
        end
      end
    end
  endtask

  task compare_reference(input [255*8:0] ref_filename);
    integer fd;
    integer ref_val;
    begin
      fd = $fopen(ref_filename, "rb");
      if (fd == 0) begin
        $display("WARNING: Reference file not found: %s — skipping comparison", ref_filename);
        $fclose(fd);
        disable compare_reference;
      end
      cmp_errors = 0;
      for (i = 0; i < TOTAL_OUTPUT; i = i + 1) begin
        ref_val = $fgetc(fd);
        if (ref_val < 0) begin
          $display("ERROR: Reference file shorter than expected at index %0d", i);
          $fclose(fd);
          disable compare_reference;
        end
        ref_buf[i] = ref_val[7:0];
        if (out_buf[i] !== ref_buf[i]) begin
          if (cmp_errors < 20)
            $display("MISMATCH at [%0d,%0d]: RTL=%0d REF=%0d",
                     i/OUTPUT_SIZE, i%OUTPUT_SIZE, out_buf[i], ref_buf[i]);
          cmp_errors = cmp_errors + 1;
        end
      end
      $fclose(fd);
      if (cmp_errors == 0)
        $display("PASS: All %0d output pixels match reference.", TOTAL_OUTPUT);
      else
        $display("FAIL: %0d / %0d pixels differ from reference.", cmp_errors, TOTAL_OUTPUT);
    end
  endtask

  task dump_output(input [255*8:0] out_filename);
    integer fd;
    begin
      fd = $fopen(out_filename, "wb");
      if (fd == 0) begin
        $display("WARNING: Cannot write output file %s", out_filename);
        disable dump_output;
      end
      for (i = 0; i < TOTAL_OUTPUT; i = i + 1)
        $fwrite(fd, "%c", out_buf[i]);
      $fclose(fd);
      $display("INFO: RTL output written to %s", out_filename);
    end
  endtask

  initial begin
    clk  = 1'b0;
    mode = 1'b0;

    $display("=== Gaussian blur test (full 258x258 image) ===");
    reset_dut;

    mode  = 1'b0;
    start = 1'b1;
    @(posedge clk); #1;
    start = 1'b0;

    fork
      feed_image("input_258x258.bin");
      collect_output;
    join

    dump_output("rtl_output_gauss.bin");
    compare_reference("ref_output_gauss.bin");

    $display("=== Sobel-X test (full 258x258 image) ===");
    reset_dut;

    mode  = 1'b1;
    start = 1'b1;
    @(posedge clk); #1;
    start = 1'b0;

    fork
      feed_image("input_258x258.bin");
      collect_output;
    join

    dump_output("rtl_output_sobel.bin");
    compare_reference("ref_output_sobel.bin");

    $display("Simulation complete.");
    $finish;
  end

  initial begin
    $dumpfile("tb_top.vcd");
    $dumpvars(0, tb_top);
  end

  initial begin
    #((TOTAL_PIXELS * 2 + 100000) * CLK_PERIOD);
    $display("TIMEOUT: simulation exceeded maximum cycle limit.");
    $finish;
  end

endmodule
