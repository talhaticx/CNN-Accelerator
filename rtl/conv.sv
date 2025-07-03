module conv #(
    parameter K = 3,    // kernel size
    parameter N = 5,    // activation map size
    parameter S = 2     // integer bits
)(
    input clk,
    input reset,
    input [S:0] activation_in [0:N-1][0:N-1],           // 3 bit activation map input
    input signed [S+1:0] kernel [0:K-1][0:K-1],         // 4 bit signed kernel input
    output [S+1:0] activation_out [0:N-2][0:N-2],       // 4 bit activation map output
    output done
);

    logic [S:0] window [0:K-1][0:K-1];      // 3 bit sliding window

    // State Encoding
    typedef enum logic [2:0] {
        IDLE,
        LOAD_WIN,
        MAC,
        STORE,
        STEP,
        DONE
    } conv_state_t;

    conv_state_t current_conv_state, next_conv_state;

    // state register
    always_ff @( posedge clk or posedge reset ) begin : conv_state_register
        case (current_conv_state)
            IDLE: begin end
            LOAD_WIN: begin end
            MAC: begin end
            STORE: begin end
            STEP: begin end
            DONE: begin end

            default: begin end
        endcase
    end

endmodule