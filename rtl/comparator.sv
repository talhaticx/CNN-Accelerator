// Comparator 2x2 Module
// Takes a 2x2 matrix of 8-bit unsigned inputs and outputs the maximum value

module comparator (
    input  logic [7:0] in [1:0][1:0],  // 2x2 input matrix
    output logic [7:0] out,            // Pooled max value
    output logic maxpool_done
);

    // intermediate maximum values
    logic [7:0] max_top;
    logic [7:0] max_bottom;

    always_comb begin
        maxpool_done = 0;
        // Compare top row
        if (in[0][0] > in[0][1])
            max_top = in[0][0];
        else
            max_top = in[0][1];

        // Compare bottom row
        if (in[1][0] > in[1][1])
            max_bottom = in[1][0];
        else
            max_bottom = in[1][1];

        // Compare max values
        if (max_top > max_bottom) begin
            out = max_top;
            maxpool_done = 1;
        end else begin
            out = max_bottom;
            maxpool_done = 1;
        end
    end

endmodule
