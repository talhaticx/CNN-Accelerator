module conv #(
    parameter int IFMAP_HEIGHT  = 128,
    parameter int IFMAP_WIDTH   = 128,
    parameter int KERNEL_HEIGHT = 5,
    parameter int KERNEL_WIDTH  = 5,
    parameter int DATA_WIDTH    = 8,
    parameter int H_STRIDE      = 1,      // Horizontal stride
    parameter int V_STRIDE      = 1,      // Vertical stride
    parameter int PADDING       = 0       // Padding size (0 for no padding)
)(
    input  logic clk,
    input  logic reset,
    input  logic en,
    
    input  logic signed [DATA_WIDTH-1:0] ifmap [0:IFMAP_HEIGHT-1][0:IFMAP_WIDTH-1],
    input  logic signed [DATA_WIDTH-1:0] weights [0:KERNEL_HEIGHT-1][0:KERNEL_WIDTH-1],
    output logic [DATA_WIDTH-1:0] ofmap [0:(IFMAP_HEIGHT-KERNEL_HEIGHT+2*PADDING)/V_STRIDE][0:(IFMAP_WIDTH-KERNEL_WIDTH+2*PADDING)/H_STRIDE],
    
    output logic done_conv
);

    // Calculate output dimensions with padding and stride
    localparam int PADDED_HEIGHT = IFMAP_HEIGHT + 2*PADDING;
    localparam int PADDED_WIDTH = IFMAP_WIDTH + 2*PADDING;
    localparam int OFMAP_HEIGHT = (PADDED_HEIGHT - KERNEL_HEIGHT) / V_STRIDE + 1;
    localparam int OFMAP_WIDTH = (PADDED_WIDTH - KERNEL_WIDTH) / H_STRIDE + 1;

    // 3x3 sliding window extracted from input feature map
    logic signed [DATA_WIDTH-1:0] window_data [0:KERNEL_HEIGHT-1][0:KERNEL_WIDTH-1];

    // MAC unit output
    // logic signed [31:0] mac_out;
    logic signed [32:0] mac_result;

    // Output after ReLU activation function
    logic signed [DATA_WIDTH-1:0] relu_out;

    // Current row and column position in the output feature map
    logic [$clog2(OFMAP_HEIGHT)-1:0] out_row;
    logic [$clog2(OFMAP_WIDTH)-1:0]  out_col;

    // Flag to indicate the last pixel of output is being processed
    logic is_last_pixel;

    // Finite State Machine states
    typedef enum logic [1:0] {
        STATE_IDLE,
        STATE_PROCESS,
        STATE_DONE
    } conv_state_t;

    conv_state_t current_state, next_state;

    // MAC (Multiply-Accumulate) Unit

    mac #(
        .KERNEL_SIZE(KERNEL_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) mac_unit (
        .feature(window_data),
        .kernel(weights),
        .result(mac_result)
    );


    // State Register
    always_ff @(posedge clk or posedge reset) begin
        if (reset || ~en)
            current_state <= STATE_IDLE;
        else
            current_state <= next_state;
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

    // Output Row/Column Counter Logic with stride
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

    // Load the KERNELxKERNEL window from the IFMAP with padding support
    always_comb begin
        for (int i = 0; i < KERNEL_HEIGHT; i++) begin
            for (int j = 0; j < KERNEL_WIDTH; j++) begin
                // Calculate original coordinates with padding offset
                int orig_row, orig_col;
                orig_row = out_row * V_STRIDE + i - PADDING;
                orig_col = out_col * H_STRIDE + j - PADDING;
                
                // Handle padding (zero-padding)
                if (orig_row < 0 || orig_row >= IFMAP_HEIGHT || 
                    orig_col < 0 || orig_col >= IFMAP_WIDTH) begin
                    window_data[i][j] = 0;  // Zero padding
                end else begin
                    window_data[i][j] = ifmap[orig_row][orig_col];
                end
            end
        end
    end

    // ReLU Activation and Output Storage
    always_comb begin
        relu_out = mac_result[DATA_WIDTH-1:0];  // Truncate to 8-bit
        ofmap[out_row][out_col] = relu_out[DATA_WIDTH-1] ? '0 : relu_out;  // ReLU
    end

    // Flag to detect end of output grid traversal
    assign is_last_pixel = (out_row == OFMAP_HEIGHT-1) && (out_col == OFMAP_WIDTH-1);

    // Output done signal when FSM enters DONE state
    assign done_conv = (current_state == STATE_DONE);

endmodule