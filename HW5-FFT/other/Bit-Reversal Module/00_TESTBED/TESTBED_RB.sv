/******************************************************************************
* Copyright (C) 2026 Marco
*
* File Name:    TESTBED_RB.sv
* Project:      [HW5] 2026 Spring DSP In VLSI @NTU <ICDA5003>
* Module:       TESTBED_RB
* Author:       Marco <harry2963753@gmail.com>
* Student ID:   M11407439
* Tool:         VCS & Verdi
* Comment Opt:  Claude Code
*
******************************************************************************/
`include "define.vh"
`timescale 1ps/1ps

module TESTBED_RB();

    logic   clk;
    logic   rst_n;
    logic   InValid;
    logic   [`DATA_WIDTH-1:0]   SDFOut;
    wire    [`DATA_WIDTH-1:0]   BROut;
    wire    OutValid;

    Reorder_Buffer DUT(.*);

    logic   [`ADDR_WIDTH-1:0]   idx_cnt;

    always #(`PERIOD_DIV) clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 1;
        InValid = 0;
        SDFOut = 0;
        idx_cnt = 0;
        repeat(2) @(negedge clk) rst_n <= ~rst_n;
        @(negedge clk);
        Input_Gen();
        #(`PERIOD_DIV*2*(`NUM+2));
        $finish;
    end

    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0, TESTBED_RB);
        $fsdbDumpMDA;
    end

    task Input_Gen;
        begin
            for(int k=0; k<2; k++) begin
                for(int i=0; i<`NUM; i++) begin
                    InValid = 1;
                    SDFOut = {27'd0, {idx_cnt[0], idx_cnt[1], idx_cnt[2], idx_cnt[3], idx_cnt[4]}};
                    idx_cnt = idx_cnt + 1;
                    @(negedge clk);
                end
            end
            InValid = 0;
            SDFOut = 0;
        end
    endtask

endmodule