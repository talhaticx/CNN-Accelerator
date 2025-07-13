// Testbench for Convolution Module with Success/Failure Reporting
module conv_tb;

    // Testbench Signals
    logic clk = 0;
    logic reset, en;
    logic signed [7:0] input_matrix [0:5][0:5];  // 6x6 input
    logic signed [7:0] kernel [0:2][0:2];       // 3x3 kernel
    logic [7:0] activation_out [0:3][0:3];      // 4x4 output
    logic done;

    // Verification Tracking
    int error_count = 0;
    int test_count = 0;
    bit verification_complete = 0;

    // Clock Generation (100MHz)
    always #5 clk = ~clk;

    // DUT Instantiation
    conv dut (
        .clk(clk),
        .reset(reset),
        .en(en),
        .activation_in(input_matrix),
        .kernel(kernel),
        .activation_out(activation_out),
        .done_conv(done)
    );

    // Waveform Dumping
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, conv_tb);
    end

    // Expected Output Calculator
    function automatic int calculate_expected(int row, int col);
        automatic int sum = 0;
        for (int i = 0; i < 3; i++) begin
            for (int j = 0; j < 3; j++) begin
                automatic int r = (row + i > 5) ? 5 : row + i;
                automatic int c = (col + j > 5) ? 5 : col + j;
                sum += input_matrix[r][c] * kernel[i][j];
            end
        end
        return sum > 0 ? sum : 0;
    endfunction

    // Verification Logic
    always @(posedge clk) begin
        if (dut.current_state == dut.STORE) begin
            automatic int expected = calculate_expected(dut.row, dut.col);
            test_count++;
            
            // Add small delay to ensure output is stable
            #1;
            
            if (activation_out[dut.row][dut.col] !== expected[7:0]) begin
                error_count++;
                $error("Mismatch at [%0d][%0d]: Expected %0d, Got %0d", 
                      dut.row, dut.col, expected, activation_out[dut.row][dut.col]);
            end else begin
                $display("Match at [%0d][%0d]: %0d", 
                        dut.row, dut.col, activation_out[dut.row][dut.col]);
            end
        end
        
        // Final check when done
        if (done && !verification_complete) begin
            verification_complete = 1;
            #10; // Small delay for final checks
            
            // Verify all outputs were tested (4x4=16)
            if (test_count != 16) begin
                error_count++;
                $error("Incomplete test: Only %0d/16 outputs verified", test_count);
            end
            
            // Final result report
            if (error_count == 0) begin
                $display("\nTEST PASSED: All %0d cases matched expected results", test_count);
                $display("SUCCESS");
            end else begin
                $display("\nTEST FAILED: %0d errors out of %0d cases", error_count, test_count);
            end
            
            // Additional check for output range
            for (int i = 0; i < 4; i++) begin
                for (int j = 0; j < 4; j++) begin
                    if (activation_out[i][j] > 255) begin
                        $warning("Output at [%0d][%0d] may be clipped: %0d", i, j, activation_out[i][j]);
                    end
                end
            end
        end
    end

    // Test Stimulus
    initial begin
        $display("Starting Convolution Testbench...");
        
        // Initialize
        en = 0;
        reset = 1;
        
        // Test Pattern (6x6)
        input_matrix = '{
            '{2, 4, 2, 4, 3, 1},
            '{1, 0, 3, 2, 2, 1},
            '{2, 4, 2, 4, 3, 1},
            '{1, 0, 3, 2, 2, 1},
            '{2, 4, 2, 4, 3, 1},
            '{1, 0, 3, 2, 2, 1}
        };

        // Kernel (3x3 averaging)
        kernel = '{
            '{8'sd1, 8'sd0, -8'sd1},
            '{8'sd2, 8'sd0, -8'sd2}, 
            '{8'sd1, 8'sd0, -8'sd1}
        };

        // Start Test
        #10;
        reset = 0;
        en = 1;
        $display("Test started with 6x6 input and 3x3 averaging kernel...");

        // Wait for Completion
        wait(done);
        #20; // Additional time for final checks

        // Display Final Output
        $display("\nFinal Convolution Output:");
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                $write("%4d", activation_out[i][j]);
            end
            $display();
        end

        // Final delay before exit
        #100;
        $finish;
    end

endmodule