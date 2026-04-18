`ifndef DEFINE_VH
    `define DEFINE_VH

    `define CLOCK_DIV   10
    `define DATA_W      11                  // 1S 1I 9F
    `define THETA_W     11                  // 1S 2I 8F
    `define MAG_W       11                  // 1S 1I 9F
    `define ITERATION   10
    `define PI          11'b0_11_00100100   // 1S 2I 8F  (+π ≈ 3.14063)
    `define NEG_PI      11'b1_00_11011100   // 1S 2I 8F  (-π ≈ -3.14063)
    `define ITER_CNT_W  $clog2(`ITERATION)
    `define PATH        "../00_TESTBED/src/"
    `define PIPE_STAGE  2
`endif
