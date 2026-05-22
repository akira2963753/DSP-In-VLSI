`define PERIOD_DIV  5
`define NUM         32     
`define DATA_WIDTH  14  // 1S6I7F
`define ADDR_WIDTH  $clog2(`NUM)
`define CNT_WIDTH   `ADDR_WIDTH
`define TWIDDLE_WIDTH   9   // 1S1I7F
`define TWIDDLE_FRAC    7
`define STAGE_SIZE  $clog2(`NUM)
`define PATH "../00_TESTBED/src/"