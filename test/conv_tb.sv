module conv_tb;

    // // Clock and control
    // logic clk = 0;
    // logic reset, en;

    // // DUT interface signals
    // logic signed [7:0] ifmap [0:127][0:127];    // 6x6 input matrix
    // logic signed [7:0] kernel [0:2][0:2];   // 3x3 kernel
    // logic        [7:0] ofmap  [0:125][0:125];   // 4x4 output
    // logic              done;


    // CONFIGURABLE PARAMETERS
    localparam int IFMAP_HEIGHT  = 128;
    localparam int IFMAP_WIDTH   = 128;
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

    // Clock Generation
    always #5 clk = ~clk;

    // DUT instantiation
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

    // Dump waveform
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, conv_tb);
    end

    // ANSI Color Macros
    `define RED     "\033[1;31m"
    `define GREEN   "\033[1;32m"
    `define YELLOW  "\033[1;33m"
    `define BLUE    "\033[1;34m"
    `define MAGENTA "\033[1;35m"
    `define CYAN    "\033[1;36m"
    `define RESET   "\033[0m"

    task automatic run_convolution_test();
        int f_out; // Declare first, before any statement

        begin
            $display(`BLUE, "Starting Convolution Test...", `RESET);

            en    = 0;
            reset = 1;
            #10;
            reset = 0;
            en    = 1;

            $display("Running with 128x128 input and 3x3 kernel...");

            wait(done);
            #10;

            f_out = $fopen("ofmap.txt", "w");
            if (!f_out) $fatal("Failed to open ofmap.txt for writing");

            foreach (ofmap[i]) begin
                foreach (ofmap[i][j]) begin
                    $fwrite(f_out, "%0d ", ofmap[i][j]);
                end
                $fwrite(f_out, "\n");
            end

            $fclose(f_out);
            $display(`GREEN, "Output feature map saved to ofmap.txt", `RESET);
            $display(`BLUE, "Test Finished.\n", `RESET);
        end
    endtask



    // Stimulus
    initial begin
        // Test 1
        int fd = $fopen("ifmap.txt", "r");
        if (!fd) $fatal("Failed to open ifmap.txt");

        foreach (ifmap[i, j]) begin
            int val;
            if ($fscanf(fd, "%d", val) != 1)
                $fatal("Read error at [%0d][%0d]", i, j);
            ifmap[i][j] = val;
        end

        $fclose(fd);

        kernel = '{
            '{8'sd0, -8'sd1, 8'sd0},
            '{-8'sd1, 8'sd4, -8'sd1},
            '{8'sd0, -8'sd1, 8'sd0}
        };
        run_convolution_test();



        $finish;
    end

endmodule
