module conv_tb1;

    // CONFIGURABLE PARAMETERS
    localparam int IFMAP_HEIGHT  = 6;
    localparam int IFMAP_WIDTH   = 6;
    localparam int KERNEL_HEIGHT = 3;
    localparam int KERNEL_WIDTH  = 3;
    localparam int DATA_WIDTH    = 8;
    localparam int H_STRIDE      = 1;
    localparam int V_STRIDE      = 1;
    localparam int PADDING       = 0;

    // DERIVED PARAMS
    localparam int OFMAP_HEIGHT = ((IFMAP_HEIGHT + 2 * PADDING - KERNEL_HEIGHT) / V_STRIDE) + 1;
    localparam int OFMAP_WIDTH  = ((IFMAP_WIDTH + 2 * PADDING - KERNEL_WIDTH) / H_STRIDE) + 1;

    // DUT Signals
    logic clk = 0;
    logic reset, en;
    logic signed [DATA_WIDTH-1:0] ifmap [0:IFMAP_HEIGHT-1][0:IFMAP_WIDTH-1];
    logic signed [DATA_WIDTH-1:0] kernel [0:KERNEL_HEIGHT-1][0:KERNEL_WIDTH-1];
    logic [DATA_WIDTH-1:0] ofmap [0:OFMAP_HEIGHT-1][0:OFMAP_WIDTH-1];
    logic done;

    int error_count = 0, test_count = 0;
    bit verification_complete = 0;

    always #5 clk = ~clk;

    conv #(
        .IFMAP_HEIGHT(IFMAP_HEIGHT),
        .IFMAP_WIDTH(IFMAP_WIDTH),
        .KERNEL_HEIGHT(KERNEL_HEIGHT),
        .KERNEL_WIDTH(KERNEL_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .H_STRIDE(H_STRIDE),
        .V_STRIDE(V_STRIDE),
        .PADDING(PADDING)
    ) dut (
        .clk(clk),
        .reset(reset),
        .en(en),
        .ifmap(ifmap),
        .weights(kernel),
        .ofmap(ofmap),
        .done_conv(done)
    );


    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, conv_tb1);
    end

    // Colors
    `define RED     "\033[1;31m"
    `define GREEN   "\033[1;32m"
    `define YELLOW  "\033[1;33m"
    `define BLUE    "\033[1;34m"
    `define MAGENTA "\033[1;35m"
    `define CYAN    "\033[1;36m"
    `define RESET   "\033[0m"

    // Expected Output
    function automatic [7:0] get_expected_pixel(int out_row, int out_col);
        int sum = 0;

        for (int i = 0; i < KERNEL_HEIGHT; i++) begin
            for (int j = 0; j < KERNEL_WIDTH; j++) begin
                int in_row = out_row * V_STRIDE + i - PADDING;
                int in_col = out_col * H_STRIDE + j - PADDING;

                int val;
                if (in_row < 0 || in_row >= IFMAP_HEIGHT || in_col < 0 || in_col >= IFMAP_WIDTH)
                    val = 0;  // padding with 0
                else
                    val = ifmap[in_row][in_col];

                sum += val * kernel[i][j];
            end
        end

        if (sum < 0)
            return 8'd0;
        else if (sum > 255)
            return 8'd255;
        else
            return sum[7:0];
    endfunction


    // Verification Logic
    always @(posedge clk) begin
        if (dut.current_state == dut.STATE_PROCESS) begin
            automatic logic [7:0] expected = get_expected_pixel(dut.out_row, dut.out_col);
            automatic logic [7:0] actual   = ofmap[dut.out_row][dut.out_col];
            test_count++;

            #1;
            if (actual !== expected) begin
                error_count++;
                $display(`RED, "Mismatch at [%0d][%0d] - Expected: %0d, Got: %0d", dut.out_row, dut.out_col, expected, actual, `RESET);
            end else begin
                $display(`GREEN, "Match at [%0d][%0d] - %0d", dut.out_row, dut.out_col, actual, `RESET);
            end
        end

        if (done && !verification_complete) begin
            verification_complete = 1;
            #10;
            if (test_count != OFMAP_HEIGHT * OFMAP_WIDTH)
                $display(`YELLOW, "Only %0d/%0d outputs verified!", test_count, OFMAP_HEIGHT * OFMAP_WIDTH, `RESET);

            if (error_count == 0)
                $display(`CYAN, "\nTEST PASSED: All %0d outputs matched.\n", test_count, `RESET);
            else
                $display(`RED, "\nTEST FAILED: %0d errors out of %0d tests.\n", error_count, test_count, `RESET);

            for (int i = 0; i < OFMAP_HEIGHT; i++) begin
                for (int j = 0; j < OFMAP_WIDTH; j++) begin
                    if (ofmap[i][j] == 8'd255)
                        $display(`MAGENTA, "Value clipped to 255 at [%0d][%0d]", i, j, `RESET);
                end
            end
        end
    end

    // Task for test run
    task automatic run_convolution_test();
        begin
            $display(`BLUE, "Starting Convolution Test...", `RESET);

            en    = 0;
            reset = 1;
            #10;
            reset = 0;
            en    = 1;

            $display("Running with %0dx%0d input and %0dx%0d kernel...", IFMAP_HEIGHT, IFMAP_WIDTH, KERNEL_HEIGHT, KERNEL_WIDTH);

            wait(done);
            #10;

            $display(`YELLOW, "\nFinal Output Feature Map:", `RESET);
            for (int i = 0; i < OFMAP_HEIGHT; i++) begin
                for (int j = 0; j < OFMAP_WIDTH; j++) begin
                    $write("%4d", ofmap[i][j]);
                end
                $display();
            end

            $display(`BLUE, "Test Finished.\n", `RESET);
        end
    endtask

    // Stimulus
    initial begin
        ifmap = '{
            '{2, 4, 2, 4, 3, 1},
            '{1, 0, 3, 2, 2, 1},
            '{2, 4, 2, 4, 3, 1},
            '{1, 0, 3, 2, 2, 1},
            '{2, 4, 2, 4, 3, 1},
            '{1, 0, 3, 2, 2, 1}
        };
        kernel = '{
            '{8'sd1,  8'sd0, -8'sd1},
            '{8'sd2,  8'sd0, -8'sd2},
            '{8'sd1,  8'sd0, -8'sd1}
        };
        run_convolution_test();

        // Add more tests as needed using same pattern

        $finish;
    end

endmodule
