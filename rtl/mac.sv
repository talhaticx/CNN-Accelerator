`timescale 1ns/1ps

module mac(
    input  logic signed [8:0] feature [2:0][2:0],
    input  logic signed [7:0] kernel  [2:0][2:0],
    output logic signed [19:0] result
);
    logic signed [15:0] p[8:0]; // products

    // Multiply stage
    always_comb begin
        for (int i = 0; i < 3; i++) begin
            for (int j = 0; j < 3; j++) begin
                p[i*3 + j] = feature[i][j] * kernel[i][j];
            end
        end
    end

    // Adder tree
    logic signed [15:0] s1[4:0];  // Stage 1: 4 adds + 1 passthrough
    logic signed [15:0] s2[1:0];  // Stage 2: 2 adds
    logic signed [15:0] s3;       // Stage 3: 1 add

    always_comb begin
        s1[0] = p[0] + p[1];
        s1[1] = p[2] + p[3];
        s1[2] = p[4] + p[5];
        s1[3] = p[6] + p[7];
        s1[4] = p[8];  // passthrough

        s2[0] = s1[0] + s1[1];
        s2[1] = s1[2] + s1[3];

        s3 = s2[0] + s2[1];

        result = s3 + s1[4];
    end

endmodule
