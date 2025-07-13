module conv (
    input logic clk,                // System clock
    input logic reset,              // Active-high reset
    input logic en,                 // Enable signal
    input logic signed [7:0] activation_in [0:5][0:5],  // 6x6 input feature map
    input logic signed [7:0] kernel [0:2][0:2],         // 3x3 convolution kernel
    output logic [7:0] activation_out [0:3][0:3],       // 4x4 output feature map
    output logic done_conv          // Convolution complete flag
);

    // 3x3 sliding window (unpacked array for direct MAC connection)
    logic signed [7:0] window [0:2][0:2];
    
    // MAC result (32-bit to prevent overflow)
    logic signed [31:0] mac_result;
    
    // Intermediate result before ReLU
    logic signed [7:0] conv_result;
    
    // Output counters (4x4 = 0-3)
    logic [1:0] row, col;
    logic iter_done;

    // State machine definition
    typedef enum logic [2:0] {
        IDLE,       // Waiting for enable
        LOAD_WIN,   // Load window from input
        MAC,        // Perform multiply-accumulate
        RELU,       // Apply ReLU activation
        STORE,      // Store result to output
        STEP,       // Move to next position
        DONE        // Operation complete
    } conv_state_t;

    conv_state_t current_state, next_state;

    // MAC Unit Instantiation
    mac mac_inst (
        .feature(window),  // Direct 3x3 window connection
        .kernel(kernel),   // Kernel weights
        .result(mac_result)
    );

    // State Register
    always_ff @(posedge clk or posedge reset) begin
        if (reset || ~en) current_state <= IDLE;
        else current_state <= next_state;
    end

    // Next State Logic
    always_comb begin
        case (current_state)
            IDLE:     next_state = en ? LOAD_WIN : IDLE;
            LOAD_WIN: next_state = MAC;
            MAC:      next_state = RELU;
            RELU:     next_state = STORE;
            STORE:    next_state = STEP;
            STEP:     next_state = iter_done ? DONE : LOAD_WIN;
            DONE:     next_state = DONE;
            default:  next_state = IDLE;
        endcase
    end

    // Row/Column Counters
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            row <= 0;
            col <= 0;
        end
        else if (en && current_state == STEP) begin
            if (col == 3) begin
                col <= 0;
                row <= row + 1;
            end else begin
                col <= col + 1;
            end
        end
    end

    // Window Loading Logic with Boundary Checking
    always_comb begin
        for (int i = 0; i < 3; i++) begin
            for (int j = 0; j < 3; j++) begin
                // Calculate indices with boundary protection
                automatic int r_idx = (row + i > 5) ? 5 : row + i;
                automatic int c_idx = (col + j > 5) ? 5 : col + j;
                window[i][j] = activation_in[r_idx][c_idx];
            end
        end
    end

    // ReLU Activation Function
    always_comb begin
        // Clip MAC result to 8 bits first
        conv_result = mac_result[7:0];
        
        // ReLU: max(0, x)
        if (conv_result[7]) begin  // If negative (MSB set)
            activation_out[row][col] = 8'b0;
        end else begin
            activation_out[row][col] = conv_result;
        end
    end

    // Output Storage (now handled in ReLU block)
    // Completion Detection
    assign iter_done = (row == 3) && (col == 3);
    assign done_conv = (current_state == DONE);

endmodule