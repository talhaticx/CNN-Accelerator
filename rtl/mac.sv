// Multiply-Accumulate Unit
// Performs element-wise multiplication and summation
// of feature window and kernel
module mac #(
    parameter int KERNEL_SIZE = 5,
    parameter int DATA_WIDTH = 8
)(
    input logic signed [DATA_WIDTH-1:0] feature [0:KERNEL_SIZE-1][0:KERNEL_SIZE-1],
    input logic signed [DATA_WIDTH-1:0] kernel [0:KERNEL_SIZE-1][0:KERNEL_SIZE-1],
    output logic signed [DATA_WIDTH*2+`$clog2(KERNEL_SIZE*KERNEL_SIZE)-1:0] result
);

    localparam int NUM_PRODUCTS = KERNEL_SIZE * KERNEL_SIZE;
    localparam int PRODUCT_WIDTH = DATA_WIDTH * 2;
    localparam int RESULT_WIDTH = PRODUCT_WIDTH + `$clog2(NUM_PRODUCTS);

    logic signed [PRODUCT_WIDTH-1:0] products [0:NUM_PRODUCTS-1];
    logic signed [RESULT_WIDTH-1:0] temp_sum;

    // Multiplication Stage
    always_comb begin
        for (int i = 0; i < KERNEL_SIZE; i++) begin
            for (int j = 0; j < KERNEL_SIZE; j++) begin
                products[i*KERNEL_SIZE + j] = feature[i][j] * kernel[i][j];
            end
        end
    end

    // Adder Tree
    always_comb begin
        temp_sum = '0;
        for (int i = 0; i < NUM_PRODUCTS; i++) begin
            temp_sum = temp_sum + products[i];
        end
    end

    assign result = temp_sum;

endmodule