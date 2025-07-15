module tb;

    // Clock and control
    logic clk = 0;
    logic reset, en;

    // DUT interface signals
    logic signed [7:0] ifmap [0:5][0:5];    // 6x6 input matrix
    logic signed [7:0] kernel [0:2][0:2];   // 3x3 kernel
    logic        [7:0] ofmap  [0:3][0:3];   // 4x4 output
    logic              done;

    // Counters and flags
    int error_count = 0;
    int test_count = 0;
    bit verification_complete = 0;

    // Clock Generation
    always #5 clk = ~clk;

    // DUT instantiation
    conv dut (
        .clk(clk),
        .reset(reset),
        .en(en),
        .ifmap(ifmap),
        .weights(kernel),
        .ofmap(ofmap),
        .done_conv(done)
    );

    // Dump waveform
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb);
    end

    // ANSI Color Macros
    `define RED     "\033[1;31m"
    `define GREEN   "\033[1;32m"
    `define YELLOW  "\033[1;33m"
    `define BLUE    "\033[1;34m"
    `define MAGENTA "\033[1;35m"
    `define CYAN    "\033[1;36m"
    `define RESET   "\033[0m"

    // Expected Output Calculation
    function automatic [7:0] get_expected_pixel(int row, int col);
        int sum = 0;
        for (int i = 0; i < 3; i++) begin
            for (int j = 0; j < 3; j++) begin
                int r = (row + i > 5) ? 5 : row + i;
                int c = (col + j > 5) ? 5 : col + j;
                sum += ifmap[r][c] * kernel[i][j];
            end
        end
        if (sum < 0)
            return 8'd0;
        else if (sum > 255)
            return 8'd255;
        else
            return sum[7:0];
    endfunction

    // Live Verification
    always @(posedge clk) begin
        if (dut.current_state == dut.STATE_PROCESS) begin
            automatic logic [7:0] expected;
            automatic logic [7:0] actual;

            expected = get_expected_pixel(dut.out_row, dut.out_col);
            actual   = ofmap[dut.out_row][dut.out_col];
            test_count++;

            #1;
            if (actual !== expected) begin
                error_count++;
                $display(`RED, "Mismatch at [%0d][%0d] - Expected: %0d, Got: %0d", dut.out_row, dut.out_col, expected, actual, `RESET);
            end else begin
                $display(`GREEN, "Match at [%0d][%0d] - %0d", dut.out_row, dut.out_col, actual, `RESET);
            end
        end

        // Final Report
        if (done && !verification_complete) begin
            verification_complete = 1;
            #10;

            if (test_count != 16) begin
                $display(`YELLOW, "Only %0d/16 outputs verified!", test_count, `RESET);
                error_count++;
            end

            if (error_count == 0)
                $display(`CYAN, "\nTEST PASSED: All %0d outputs matched.\n", test_count, `RESET);
            else
                $display(`RED, "\nTEST FAILED: %0d errors out of %0d tests.\n", error_count, test_count, `RESET);

            for (int i = 0; i < 4; i++) begin
                for (int j = 0; j < 4; j++) begin
                    if (ofmap[i][j] == 8'd255)
                        $display(`MAGENTA, "Value clipped to 255 at [%0d][%0d]", i, j, `RESET);
                end
            end
        end
    end

    task automatic run_convolution_test();
        begin
            $display(`BLUE, "Starting Convolution Test...", `RESET);

            en    = 0;
            reset = 1;
            #10;
            reset = 0;
            en    = 1;

            $display("Running with 6x6 input and 3x3 kernel...");

            wait(done);
            #10;

            $display(`YELLOW, "\nFinal Output Feature Map:", `RESET);
            for (int i = 0; i < 4; i++) begin
                for (int j = 0; j < 4; j++) begin
                    $write("%4d", ofmap[i][j]);
                end
                $display();
            end

            $display(`BLUE, "Test Finished.\n", `RESET);
        end
    endtask

    // Stimulus
    initial begin
        // Test 1
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

        // Test 2
        ifmap = '{
            '{1, 0, 1, 0, 1, 0},
            '{0, 1, 0, 1, 0, 1},
            '{1, 0, 1, 0, 1, 0},
            '{0, 1, 0, 1, 0, 1},
            '{1, 0, 1, 0, 1, 0},
            '{0, 1, 0, 1, 0, 1}
        };
        kernel = '{
            '{8'sd0, -8'sd1, 8'sd0},
            '{-8'sd1, 8'sd4, -8'sd1},
            '{8'sd0, -8'sd1, 8'sd0}
        };
        run_convolution_test();

        // Test 3 (All Zeros)
        ifmap = '{default: '{default: 0}};
        kernel = '{default: '{default: 1}};
        run_convolution_test();


        // Test for 5x5 ifmap
        
        // ifmap = '{
        //     '{1, 0, 1, 0, 1},
        //     '{0, 1, 0, 1, 0},
        //     '{1, 0, 1, 0, 1},
        //     '{0, 1, 0, 1, 0},
        //     '{1, 0, 1, 0, 1}
        // };

        // kernel = '{
        //     '{8'sd0, -8'sd1, 8'sd0},
        //     '{-8'sd1, 8'sd4, -8'sd1},
        //     '{8'sd0, -8'sd1, 8'sd0}
        // };
        // run_convolution_test();

        $finish;
    end

endmodule
