module conv #(
    parameter int IFMAP_HEIGHT  = 6,
    parameter int IFMAP_WIDTH   = 6,

    parameter int KERNEL_HEIGHT = 3,
    parameter int KERNEL_WIDTH  = 3,

    parameter int OFMAP_HEIGHT  = 4,
    parameter int OFMAP_WIDTH   = 4,

    parameter int DATA_WIDTH    = 8      // Bit-width for input/output values
)(
    input  logic clk,                                       // System clock
    input  logic reset,                                     // Active-high reset
    input  logic en,                                        // Enable signal for starting convolution

    input  logic signed [DATA_WIDTH-1:0] ifmap [0:IFMAP_HEIGHT-1][0:IFMAP_WIDTH-1],             // Input Feature Map: 6x6 image (signed for flexibility)
    input  logic signed [DATA_WIDTH-1:0] weights [0:KERNEL_HEIGHT-1][0:KERNEL_WIDTH-1],         // 3x3 Convolution Kernel (signed values)
    output logic [DATA_WIDTH-1:0] ofmap [0:OFMAP_HEIGHT-1][0:OFMAP_WIDTH-1],                    // Output Feature Map: 4x4 convolved output (unsigned, ReLU applied)
    
    output logic              done_conv                     // Done flag: High when convolution is complete
);

    // 3x3 sliding window extracted from input feature map
    logic signed [DATA_WIDTH-1:0] window_data [0:KERNEL_HEIGHT-1][0:KERNEL_WIDTH-1];

    // MAC unit output: 32-bit to prevent overflow from 3x3 accumulation
    logic signed [31:0] mac_out;

    // Output after ReLU activation function (clipped to 8 bits)
    logic signed [DATA_WIDTH-1:0] relu_out;

    // Current row and column position in the output feature map (4x4)
    logic [$clog2(OFMAP_HEIGHT)-1:0] out_row;
    logic [$clog2(OFMAP_WIDTH)-1:0]  out_col;

    // Flag to indicate the last pixel of output is being processed
    logic       is_last_pixel;

    // Finite State Machine states
    typedef enum logic [1:0] {
        STATE_IDLE,     // Waiting for enable signal
        STATE_PROCESS,  // Perform convolution operation (load window, MAC, ReLU, write output)
        STATE_DONE      // All pixels processed, raise done_conv
    } conv_state_t;

    conv_state_t current_state, next_state;

    // MAC (Multiply-Accumulate) Unit instantiation
    // Takes a 3x3 window and 3x3 kernel, computes sum of element-wise products
    mac mac_inst (
        .feature(window_data),
        .kernel(weights),
        .result(mac_out)
    );

    // State Register: Advances FSM on every clock if enabled
    always_ff @(posedge clk or posedge reset) begin
        if (reset || ~en)
            current_state <= STATE_IDLE;  // Reset to idle on reset or disable
        else
            current_state <= next_state;  // Move to next state
    end

    // FSM Next State Logic
    always_comb begin
        case (current_state)
            STATE_IDLE:     next_state = en ? STATE_PROCESS : STATE_IDLE;
            STATE_PROCESS:  next_state = is_last_pixel ? STATE_DONE : STATE_PROCESS;
            STATE_DONE:     next_state = STATE_DONE;
            default:        next_state = STATE_IDLE;
        endcase
    end

    // Output Row/Column Counter Logic
    // Traverses the 4x4 OFMAP grid from (0,0) to (3,3)
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            out_row <= 0;
            out_col <= 0;
        end else if (en && current_state == STATE_PROCESS) begin
            if (out_col == OFMAP_WIDTH-1) begin
                out_col <= 0;
                out_row <= out_row + 1;
            end else begin
                out_col <= out_col + 1;
            end
        end
    end

    // Load the 3x3 window from the IFMAP
    // Handles boundary by clamping to the max index (5)
    always_comb begin
        // Row 0
        window_data[0][0] = ifmap[out_row + 0 > IFMAP_HEIGHT-1 ? IFMAP_HEIGHT-1 : out_row + 0][out_col + 0 > IFMAP_WIDTH-1 ? IFMAP_WIDTH-1 : out_col + 0];
        window_data[0][1] = ifmap[out_row + 0 > IFMAP_HEIGHT-1 ? IFMAP_HEIGHT-1 : out_row + 0][out_col + 1 > IFMAP_WIDTH-1 ? IFMAP_WIDTH-1 : out_col + 1];
        window_data[0][2] = ifmap[out_row + 0 > IFMAP_HEIGHT-1 ? IFMAP_HEIGHT-1 : out_row + 0][out_col + 2 > IFMAP_WIDTH-1 ? IFMAP_WIDTH-1 : out_col + 2];

        // Row 1
        window_data[1][0] = ifmap[out_row + 1 > IFMAP_HEIGHT-1 ? IFMAP_HEIGHT-1 : out_row + 1][out_col + 0 > IFMAP_WIDTH-1 ? IFMAP_WIDTH-1 : out_col + 0];
        window_data[1][1] = ifmap[out_row + 1 > IFMAP_HEIGHT-1 ? IFMAP_HEIGHT-1 : out_row + 1][out_col + 1 > IFMAP_WIDTH-1 ? IFMAP_WIDTH-1 : out_col + 1];
        window_data[1][2] = ifmap[out_row + 1 > IFMAP_HEIGHT-1 ? IFMAP_HEIGHT-1 : out_row + 1][out_col + 2 > IFMAP_WIDTH-1 ? IFMAP_WIDTH-1 : out_col + 2];

        // Row 2
        window_data[2][0] = ifmap[out_row + 2 > IFMAP_HEIGHT-1 ? IFMAP_HEIGHT-1 : out_row + 2][out_col + 0 > IFMAP_WIDTH-1 ? IFMAP_WIDTH-1 : out_col + 0];
        window_data[2][1] = ifmap[out_row + 2 > IFMAP_HEIGHT-1 ? IFMAP_HEIGHT-1 : out_row + 2][out_col + 1 > IFMAP_WIDTH-1 ? IFMAP_WIDTH-1 : out_col + 1];
        window_data[2][2] = ifmap[out_row + 2 > IFMAP_HEIGHT-1 ? IFMAP_HEIGHT-1 : out_row + 2][out_col + 2 > IFMAP_WIDTH-1 ? IFMAP_WIDTH-1 : out_col + 2];
    end

    // ReLU Activation and Output Storage
    // ReLU: output = max(0, MAC_result)
    // Also clips MAC result to 8-bit for OFMAP
    always_comb begin
        relu_out = mac_out[DATA_WIDTH-1:0];  // Truncate to 8-bit
        ofmap[out_row][out_col] = relu_out[DATA_WIDTH-1] ? '0 : relu_out;  // ReLU: if negative, set to 0
    end

    // Flag to detect end of 4x4 grid traversal
    assign is_last_pixel = (out_row == OFMAP_HEIGHT-1) && (out_col == OFMAP_WIDTH-1);

    // Output done signal when FSM enters DONE state
    assign done_conv = (current_state == STATE_DONE);

endmodule
