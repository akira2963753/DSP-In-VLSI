/******************************************************************************
* Copyright (C) 2026 Marco
*
* File Name:    TESTBED.sv
* Project:      [HW5] 2026 Spring DSP In VLSI @NTU <ICDA5003>
* Module:       TESTBED
* Author:       Marco <harry2963753@gmail.com>
* Student ID:   M11407439
* Tool:         VCS & Verdi
* Comment Opt:  Claude Code
*
******************************************************************************/
`include "define.vh"
`timescale 1ps/1ps


module TESTBED();

    logic clk;
    logic rst_n;
    logic InValid;
    logic signed [`DATA_WIDTH-1:0] FFTInRe;
    logic signed [`DATA_WIDTH-1:0] FFTInIm;
    wire  signed [`DATA_WIDTH-1:0] BROutRe;
    wire  signed [`DATA_WIDTH-1:0] BROutIm;
    wire OutValid;

    logic signed [`DATA_WIDTH-1:0] FFTInRe_Temp [0:`NUM-1];
    logic signed [`DATA_WIDTH-1:0] FFTInIm_Temp [0:`NUM-1];
    logic signed [`DATA_WIDTH-1:0] BROutRe_Temp [0:`NUM-1];
    logic signed [`DATA_WIDTH-1:0] BROutIm_Temp [0:`NUM-1];

    FFT_IP DUT(.*);

    initial begin
        $readmemh({`PATH, "FFT_INPUT32_REAL.dat"}, FFTInRe_Temp);
        $readmemh({`PATH, "FFT_INPUT32_IMAG.dat"}, FFTInIm_Temp);
    end

    always #(`PERIOD_DIV) clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 1;
        InValid = 0;
        FFTInRe = 0;
        FFTInIm = 0;
        repeat(2) @(negedge clk) rst_n = ~rst_n;
        @(negedge clk);
        INPUT_GEN();
        #((`NUM*2+2)*(`PERIOD_DIV*2));
        $writememh({`PATH, "BROutRe.dat"}, BROutRe_Temp);
        $writememh({`PATH, "BROutIm.dat"}, BROutIm_Temp);
        #10 $finish;
    end

    task INPUT_GEN;
        begin
            for(int i = 0; i<`NUM; i=i+1) begin
                FFTInRe = FFTInRe_Temp[i];
                FFTInIm = FFTInIm_Temp[i];
                InValid = 1;
                @(negedge clk);
            end
            FFTInRe = 0;
            FFTInIm = 0;
            InValid = 0;
        end
    endtask

    logic [`CNT_WIDTH-1:0] out_cnt;

    // Capture Output
    always @(negedge clk or negedge rst_n) begin
        if(!rst_n) out_cnt <= 0;
        else if(OutValid) begin
            BROutRe_Temp[out_cnt] <= BROutRe;
            BROutIm_Temp[out_cnt] <= BROutIm;
            out_cnt <= out_cnt + 1;
        end
        else;
    end

    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0, TESTBED);
        $fsdbDumpMDA;
    end

endmodule