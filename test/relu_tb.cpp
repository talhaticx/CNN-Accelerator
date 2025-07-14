#include "Vrelu.h"
#include "verilated.h"
#include <cstdint>
#include <iostream>

vluint64_t sim_time = 0;

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vrelu* top = new Vrelu;

    int error_count = 0;

    // Iterate over all 20-bit signed values: -524288 to 524287
    for (int32_t val = -524288; val <= 524287; ++val) {
        top->in = val;     // Apply input

        top->eval();       // Evaluate
        sim_time++;

        // Expected ReLU behavior with arithmetic right shift
        int32_t expected = (val < 0) ? 0 : (val >> 12);

        if (top->out != expected) {
            std::cout << "❌ FAIL at " << sim_time << " - Input: " << val
                      << ", Output: " << top->out
                      << ", Expected: " << expected << std::endl;
            error_count++;
        }

        // Optional: Stop early for testing
        // if (sim_time > 10000) break;
    }

    std::cout << "----------------------------------" << std::endl;
    if (error_count == 0)
        std::cout << "✅ All 1,048,576 cases passed." << std::endl;
    else
        std::cout << "❌ " << error_count << " total mismatches found." << std::endl;

    delete top;
    return 0;
}
