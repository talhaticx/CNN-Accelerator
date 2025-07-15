// Multiply-Accumulate Unit
// Performs element-wise multiplication and summation
// of 3x3 feature window and kernel
module mac(
    input logic signed [7:0] feature [0:2][0:2],  // 3x3 feature window
    input logic signed [7:0] kernel [0:2][0:2],   // 3x3 kernel weights
    output logic signed [31:0] result             // 32-bit result
);
    // Intermediate products (8-bit * 8-bit = 16-bit)
    logic signed [15:0] products [0:8];
    
    // Adder tree stages
    logic signed [16:0] sum_stage1 [0:3];  // 17-bit after first add
    logic signed [17:0] sum_stage2 [0:1];  // 18-bit after second add
    logic signed [18:0] sum_stage3;        // 19-bit after third add

    // Multiplication Stage
    always_comb begin
        for (int i = 0; i < 3; i++) begin
            for (int j = 0; j < 3; j++) begin
                products[i*3 + j] = feature[i][j] * kernel[i][j];
            end
        end
    end

    // Adder Tree Stage 1
    always_comb begin
        sum_stage1[0] = products[0] + products[1];
        sum_stage1[1] = products[2] + products[3];
        sum_stage1[2] = products[4] + products[5];
        sum_stage1[3] = products[6] + products[7];
    end

    // Adder Tree Stage 2
    always_comb begin
        sum_stage2[0] = sum_stage1[0] + sum_stage1[1];
        sum_stage2[1] = sum_stage1[2] + sum_stage1[3];
    end

    // Final Summation
    always_comb begin
        sum_stage3 = sum_stage2[0] + sum_stage2[1];
        result = sum_stage3 + products[8]; // Include last product
    end

endmodule