module cnn_accelerator_tb;

    // Parameters
    localparam int IFMAP_HEIGHT = 128;
    localparam int IFMAP_WIDTH = 128;
    localparam int KERNEL_HEIGHT = 5;
    localparam int KERNEL_WIDTH = 5;
    localparam int DATA_WIDTH = 8;
    localparam int H_STRIDE = 1;
    localparam int V_STRIDE = 1;
    localparam int PADDING = 0;

    // Derived Parameters
    localparam int CONV_OFMAP_HEIGHT = ((IFMAP_HEIGHT + 2 * PADDING - KERNEL_HEIGHT) / V_STRIDE) + 1;
    localparam int CONV_OFMAP_WIDTH = ((IFMAP_WIDTH + 2 * PADDING - KERNEL_WIDTH) / H_STRIDE) + 1;
    localparam int POOL_OFMAP_HEIGHT = CONV_OFMAP_HEIGHT / 2;
    localparam int POOL_OFMAP_WIDTH = CONV_OFMAP_WIDTH / 2;

    // Signals
    logic clk = 0;
    logic reset, en;
    logic signed [DATA_WIDTH-1:0] ifmap [0:IFMAP_HEIGHT-1][0:IFMAP_WIDTH-1];
    logic signed [DATA_WIDTH-1:0] kernel [0:KERNEL_HEIGHT-1][0:KERNEL_WIDTH-1];
    logic [DATA_WIDTH-1:0] conv_ofmap [0:CONV_OFMAP_HEIGHT-1][0:CONV_OFMAP_WIDTH-1];
    logic [DATA_WIDTH-1:0] pool_ofmap [0:POOL_OFMAP_HEIGHT-1][0:POOL_OFMAP_WIDTH-1];
    logic done_conv, done_pool;

    // Clock Generation
    always #5 clk = ~clk;

    // DUT Instantiation
    conv #(
        .IFMAP_HEIGHT(IFMAP_HEIGHT),
        .IFMAP_WIDTH(IFMAP_WIDTH),
        .KERNEL_HEIGHT(KERNEL_HEIGHT),
        .KERNEL_WIDTH(KERNEL_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .H_STRIDE(H_STRIDE),
        .V_STRIDE(V_STRIDE),
        .PADDING(PADDING)
    ) conv_inst (
        .clk(clk),
        .reset(reset),
        .en(en),
        .ifmap(ifmap),
        .weights(kernel),
        .ofmap(conv_ofmap),
        .done_conv(done_conv)
    );

    maxpool #(
        .IFMAP_HEIGHT(CONV_OFMAP_HEIGHT),
        .IFMAP_WIDTH(CONV_OFMAP_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) maxpool_inst (
        .clk(clk),
        .reset(reset),
        .en(done_conv), // Trigger maxpool after conv is done
        .ifmap(conv_ofmap),
        .ofmap(pool_ofmap),
        .done_pool(done_pool)
    );

    // Task: Load ifmap
    task load_ifmap_from_file();
        int file, i, j, value;
        file = $fopen("ifmap.txt", "r");
        if (file == 0) begin
            $display("Could not open ifmap.txt, using fallback pattern.");
            for (i = 0; i < IFMAP_HEIGHT; i++)
                for (j = 0; j < IFMAP_WIDTH; j++)
                    ifmap[i][j] = (i + j) % 256;
        end else begin
            $display("Loading ifmap from ifmap.txt...");
            for (i = 0; i < IFMAP_HEIGHT; i++)
                for (j = 0; j < IFMAP_WIDTH; j++)
                    if ($fscanf(file, "%d", value) == 1)
                        ifmap[i][j] = value;
                    else
                        ifmap[i][j] = 0;
            $fclose(file);
            $display("Ifmap loaded successfully.");
        end
    endtask

    // Task: Save output to file
    task save_ofmap_to_file();
        int file, i, j;
        file = $fopen("ofmap.txt", "w");
        if (file == 0) begin
            $display("Error: Could not create ofmap.txt");
            return;
        end
        $display("Writing output to ofmap.txt...");
        for (i = 0; i < POOL_OFMAP_HEIGHT; i++) begin
            for (j = 0; j < POOL_OFMAP_WIDTH; j++) begin
                $fwrite(file, "%d", pool_ofmap[i][j]);
                if (j < POOL_OFMAP_WIDTH - 1) $fwrite(file, " ");
            end
            $fwrite(file, "\n");
        end
        $fclose(file);
        $display("Output written to ofmap.txt");
    endtask

    // Stimulus
    initial begin
        $dumpfile("wave_full_chain.vcd");
        $dumpvars(0, cnn_accelerator_tb);

        // Initialize kernel
        kernel = '{
            '{ 1,  0, -1,  0,  1},
            '{ 1,  0, -1,  0,  1},
            '{ 1,  0, -1,  0,  1},
            '{ 1,  0, -1,  0,  1},
            '{ 1,  0, -1,  0,  1}
        };

        load_ifmap_from_file();

        reset = 1;
        en = 0;
        #10;
        reset = 0;
        #10;
        en = 1;

        // Wait for done_pool or timeout
                fork
            wait(done_pool);
            begin
                #300000;
                $display("ERROR: Simulation timeout - done_pool never asserted");
                $finish;
            end
        join_any
        disable fork;

                #20;
        save_ofmap_to_file();

        $display("Simulation finished.");
        $finish;
    end

endmodule
