`ifndef DEFINE_VH
    `define DEFINE_VH

    `define CLOCK_DIV   10
    `define NUM_TEST    10
    `define DATA_W      14                  // 1S 1I 12F
    `define THETA_W     13                  // 1S 2I 10F
    `define ITERATION   12
    `define PI          13'b0_11_0010010001 // 1S 2I 10F
    `define NEG_PI      13'b1_00_1101101111 // 1S 2I 10F  
    `define ITER_CNT_W  $clog2(`ITERATION)
    `define PATH        "../00_TESTBED/src/"
    `define PIPE_STAGE  2
`endif
