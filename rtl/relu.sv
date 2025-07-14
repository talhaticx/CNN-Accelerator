// ReLU Module: output = max(0, input)

module relu (
    input  logic signed [15:0] in,   // Signed input
    output logic signed [15:0] out   // ReLU output
);

    always_comb begin
        if (in[19])
            out = 0;
        else
            out = in >>> 8;
    end

endmodule
