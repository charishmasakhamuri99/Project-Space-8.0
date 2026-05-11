`define IMAGE_WIDTH  10    
`define IMAGE_HEIGHT 10    
`define OUTPUT_SIZE  8     
`define CLK_PERIOD   10    
`define TOTAL_PIXELS (`IMAGE_WIDTH * `IMAGE_HEIGHT)
`define TOTAL_OUTPUT (`OUTPUT_SIZE * `OUTPUT_SIZE)


`timescale 1ns/1ps

module tb_top;

  // DUT ports
  reg        clk, rst, start, mode;
  reg  [7:0] pixel_in;
  reg        pixel_valid;
  wire       pixel_ready;
  wire [7:0] pixel_out;
  wire       pixel_out_valid;
  wire       done;

  // DUT instantiation
  top #(
    .IMAGE_WIDTH (`IMAGE_WIDTH),
    .IMAGE_HEIGHT(`IMAGE_HEIGHT),
    .OUTPUT_SIZE (`OUTPUT_SIZE)
  ) dut(
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

  // Clock generation
  initial clk = 0;
  always #(`CLK_PERIOD/2) clk = ~clk;

  reg [7:0] test_image[`TOTAL_PIXELS-1:0];

  // Output capture
  reg [7:0] output_pixels[`TOTAL_OUTPUT-1:0];
  integer   out_idx;
  integer   total_out;

  integer   pix_file;
  integer   scan_ret;
  integer   tmp_pix;
  integer   pix_idx;
  integer   r, c;

 
  task load_pixels_from_file;
    integer k;
    begin
      pix_file = $fopen("pixels.txt", "r");
      if(pix_file == 0) begin
        $display("ERROR: Could not open pixels.txt — using zero image as fallback.");
        for(k=0; k<`TOTAL_PIXELS; k=k+1)
          test_image[k] = 8'h00;
      end
      else begin
        for(k=0; k<`TOTAL_PIXELS; k=k+1) begin
          scan_ret = $fscanf(pix_file, "%d\n", tmp_pix);
          if(scan_ret == 1)
            test_image[k] = tmp_pix[7:0];
          else begin
            $display("WARNING: pixels.txt ended early at index %0d — padding with 0.", k);
            test_image[k] = 8'h00;
          end
        end
        $fclose(pix_file);
        $display("INFO: Loaded %0d pixels from pixels.txt.", `TOTAL_PIXELS);
      end
    end
  endtask

  task feed_pixels;
    begin
      pix_idx = 0;
      while(pix_idx < `TOTAL_PIXELS) begin
        @(posedge clk);
        if(pixel_ready) begin
          pixel_in    = test_image[pix_idx];
          pixel_valid = 1'b1;
          pix_idx     = pix_idx + 1;
        end
        else
          pixel_valid = 1'b0;
      end
      @(posedge clk);
      pixel_valid = 1'b0;
    end
  endtask

  

  // Main test sequence
  initial begin
    rst         = 1'b0;   // active-low reset — assert (drive low) to reset
    start       = 1'b0;
    mode        = 1'b1;   
    pixel_in    = 8'h00;
    pixel_valid = 1'b0;
    out_idx     = 0;
    total_out   = 0;

    load_pixels_from_file;

    repeat(5) @(posedge clk);
    rst = 1'b1;            // de-assert reset (drive high = normal operation)
    @(posedge clk);

    $display("=== SOBEL-X TEST ===");
    $display("Image  : %0dx%0d", `IMAGE_WIDTH, `IMAGE_HEIGHT);
    $display("Output : %0dx%0d", `OUTPUT_SIZE, `OUTPUT_SIZE);

    @(posedge clk);
    start = 1'b1;
    @(posedge clk);
    start = 1'b0;

    feed_pixels;

    wait(done);
    @(posedge clk);
    $display("=== SOBEL-X DONE. Output pixels collected: %0d ===", total_out);
    $display("Expected : %0d", `TOTAL_OUTPUT);

    if(total_out == `TOTAL_OUTPUT)
      $display("PASS: Output pixel count correct.");
    else
      $display("FAIL: Output pixel count mismatch.");

    $display("First output row:");
    for(c=0; c<`OUTPUT_SIZE; c=c+1)
      $write("%0d ", output_pixels[c]);
    $display("");

    rst       = 1'b0;   
    mode      = 1'b0;
    out_idx   = 0;
    total_out = 0;
    repeat(5) @(posedge clk);
    rst   = 1'b1;
    start = 1'b1;
    @(posedge clk);
    start = 1'b0;

    $display("=== GAUSSIAN TEST ===");

    feed_pixels;

    wait(done);
    @(posedge clk);
    $display("Gaussian done. Output pixels: %0d", total_out);

    $display("First output row:");
    for(c=0; c<`OUTPUT_SIZE; c=c+1)
      $write("%0d ", output_pixels[c]);
    $display("");

    #(`CLK_PERIOD * 10);
    $display("Simulation complete.");
    $finish;
  end

  always@(posedge clk) begin
    if(pixel_out_valid) begin
      if(out_idx < `TOTAL_OUTPUT)
        output_pixels[out_idx] = pixel_out;
      out_idx   = out_idx + 1;
      total_out = total_out + 1;
    end
  end

  // Timeout watchdog
  initial begin
    #(`CLK_PERIOD * 200000);
    $display("TIMEOUT — simulation did not complete.");
    $finish;
  end

endmodule
