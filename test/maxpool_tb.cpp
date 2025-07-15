#include "Vmaxpool.h"
#include "verilated.h"
#include <iostream>
#include <iomanip>

void run_test(Vmaxpool* dut, uint8_t a, uint8_t b, uint8_t c, uint8_t d, uint8_t expected) {
    dut->in[0][0] = a;
    dut->in[0][1] = b;
    dut->in[1][0] = c;
    dut->in[1][1] = d;

    dut->eval(); // Evaluate the design

    std::cout << "Input: [[" << (int)a << ", " << (int)b << "], ["
              << (int)c << ", " << (int)d << "]] -> Max: "
              << std::setw(3) << (int)dut->out << " (Expected: "
              << std::setw(3) << (int)expected << ") "
              << ((dut->out == expected && dut->maxpool_done) ? "PASS" : "FAIL")
              << std::endl;
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vmaxpool* dut = new Vmaxpool;

    std::cout << "Running Max Pool 2x2 C++ testbench...\n";

    run_test(dut, 1,   2,   3,   4,   4);
    run_test(dut, 7,   7,   7,   7,   7);
    run_test(dut, 0, 255, 100, 200, 255);
    run_test(dut, 255, 0,   1,   2, 255);
    run_test(dut, 15, 10,  20,   5,  20);

    std::cout << "All tests completed.\n";

    delete dut;
    return 0;
}
