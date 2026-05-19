`define PERIOD_DIV  5
`define NUM         32     
`define DATA_WIDTH  16  // 1S6I9F
`define ADDR_WIDTH  $clog2(`NUM)
`define CNT_WIDTH   `ADDR_WIDTH
`define TWIDDLE_WIDTH   11
`define STAGE_SIZE  $clog2(`NUM)
`define PATH "../00_TESTBED/src/"