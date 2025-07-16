module maxpool #(
    parameter int IFMAP_HEIGHT = 128,
    parameter int IFMAP_WIDTH  = 128,
    parameter int DATA_WIDTH   = 8
)(
    input  logic clk,
    input  logic reset,
    input  logic en,

    input  logic [DATA_WIDTH-1:0] ifmap [0:IFMAP_HEIGHT-1][0:IFMAP_WIDTH-1],
    output logic [DATA_WIDTH-1:0] ofmap [0:(IFMAP_HEIGHT/2)-1][0:(IFMAP_WIDTH/2)-1],

    output logic done_pool
);

    localparam int STRIDE       = 2;
    localparam int POOL_SIZE    = 2;
    localparam int OFMAP_HEIGHT = IFMAP_HEIGHT / POOL_SIZE;
    localparam int OFMAP_WIDTH  = IFMAP_WIDTH  / POOL_SIZE;

    logic [$clog2(OFMAP_HEIGHT)-1:0] out_row;
    logic [$clog2(OFMAP_WIDTH)-1:0]  out_col;

    logic [DATA_WIDTH-1:0] window [0:1][0:1];
    logic [DATA_WIDTH-1:0] max_val;
    logic maxpool_done;

    typedef enum logic [2:0] {
        IDLE,
        LOAD_WINDOW,
        COMPARE,
        STORE_RESULT,
        DONE
    } state_t;

    state_t state, next_state;

    // Instantiate comparator module
    comparator pool_comp (
        .in(window),
        .out(max_val),
        .maxpool_done(maxpool_done)
    );

    // FSM: State Register
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    // FSM: Next State Logic
    always_comb begin
        case (state)
            IDLE: begin
                if (en)
                    next_state = LOAD_WINDOW;
                else
                    next_state = IDLE;
            end

            LOAD_WINDOW: begin
                next_state = COMPARE;
            end

            COMPARE: begin
                if (maxpool_done)
                    next_state = STORE_RESULT;
                else
                    next_state = COMPARE;
            end

            STORE_RESULT: begin
                if (out_row == OFMAP_HEIGHT-1 && out_col == OFMAP_WIDTH-1)
                    next_state = DONE;
                else
                    next_state = LOAD_WINDOW;
            end

            DONE: next_state = DONE;

            default: next_state = IDLE;
        endcase
    end

    // Output Counters
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            out_row <= 0;
            out_col <= 0;
        end else if (state == STORE_RESULT) begin
            if (out_col == OFMAP_WIDTH - 1) begin
                out_col <= 0;
                out_row <= out_row + 1;
            end else begin
                out_col <= out_col + 1;
            end
        end
    end

    // Load 2x2 window from input feature map
    always_ff @(posedge clk) begin
        if (state == LOAD_WINDOW) begin
            // Manually load values using if-statements
            if (out_row * STRIDE < IFMAP_HEIGHT && out_col * STRIDE < IFMAP_WIDTH)
                window[0][0] <= ifmap[out_row * STRIDE][out_col * STRIDE];

            if (out_row * STRIDE < IFMAP_HEIGHT && (out_col * STRIDE + 1) < IFMAP_WIDTH)
                window[0][1] <= ifmap[out_row * STRIDE][out_col * STRIDE + 1];

            if ((out_row * STRIDE + 1) < IFMAP_HEIGHT && out_col * STRIDE < IFMAP_WIDTH)
                window[1][0] <= ifmap[out_row * STRIDE + 1][out_col * STRIDE];

            if ((out_row * STRIDE + 1) < IFMAP_HEIGHT && (out_col * STRIDE + 1) < IFMAP_WIDTH)
                window[1][1] <= ifmap[out_row * STRIDE + 1][out_col * STRIDE + 1];
        end
    end

    // Store max value to ofmap
    always_ff @(posedge clk) begin
        if (state == STORE_RESULT) begin
            ofmap[out_row][out_col] <= max_val;
        end
    end

    // Done signal
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            done_pool <= 0;
        else if (state == DONE)
            done_pool <= 1;
    end

endmodule
