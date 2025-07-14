#include "Vmac.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>
#include <cassert>

vluint64_t sim_time = 0;

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vmac* top = new Vmac;

    // Enable VCD dump
    VerilatedVcdC* tfp = new VerilatedVcdC;
    Verilated::traceEverOn(true);
    top->trace(tfp, 99);
    tfp->open("mac.vcd");

    // === Fixed 3x3 Matrices ===
    int16_t feature[3][3] = {
        {0, 0, 0},
        {0, 255, 0},
        {0, 255, 255}
    };

    int8_t kernel[3][3] = {
        {1, 0, -1},
        {1, 0, -1},
        {1, 0, -1}
    };

    int expected = 0;

    // Apply inputs to DUT and compute expected value
    for (int i = 0; i < 3; ++i)
        for (int j = 0; j < 3; ++j) {
            top->feature[i][j] = feature[i][j];
            top->kernel[i][j] = kernel[i][j];
            expected += feature[i][j] * kernel[i][j];
        }

    // Evaluate model
    top->eval();
    tfp->dump(sim_time++);

    // Output results
    std::cout << "Result from DUT:   " << top->result << std::endl;
    std::cout << "Expected result:   " << expected << std::endl;

    if (top->result == expected)
        std::cout << "✅ PASS" << std::endl;
    else
        std::cout << "❌ FAIL" << std::endl;

    // Clean up
    tfp->close();
    delete tfp;
    delete top;

    return 0;
}
