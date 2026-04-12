`ifndef DEFINE_VH
    `define DEFINE_VH

    // I/O Width
    `define IO_WIDTH    16
    `define MU_WIDTH    `IO_WIDTH

    // BF16 Format
    `define EXP_WIDTH   8
    `define MIN_WIDTH   7
    `define HALF_MUL    16'h3f00  // 0.5 in BF16

    // Interpolator
    `define NUM         3

    // Testbench
    `define MU_NUM      8
    `define TESTCASE    13
    `define CLK_PERIOD  10
    `define Path        "../00_TESTBED/src/"

`endif
