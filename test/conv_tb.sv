module conv_tb;

  logic [2:0] input_matrix [0:4][0:4];  // 3-bit unsigned
  logic signed [3:0] kernel [0:2][0:2]; // 4-bit signed

  initial begin
    // Input matrix (5x5 example)
    input_matrix[0] = '{2, 4, 2, 4, 3};
    input_matrix[1] = '{1, 0, 3, 2, 2};
    input_matrix[2] = '{2, 4, 2, 4, 3};
    input_matrix[3] = '{1, 0, 3, 2, 2};
    input_matrix[4] = '{2, 4, 2, 4, 3};

    // Kernel (3x3)
    kernel[0] = '{-1, 0, 1};
    kernel[1] = '{-2, 0, 2};
    kernel[2] = '{-1, 0, 1};


    $display("Test");
    $finish;
  end

endmodule