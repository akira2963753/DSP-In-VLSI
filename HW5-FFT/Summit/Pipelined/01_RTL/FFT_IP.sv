/******************************************************************************
* Copyright (C) 2026 Marco
*
* File Name:    FFT_IP.sv
* Project:      [HW5] 2026 Spring DSP In VLSI @NTU <ICDA5003>
* Module:       FFT_IP
* Author:       Marco <harry2963753@gmail.com>
* Student ID:   M11407439
* Tool:         VCS & Verdi
* Comment Opt:  Claude Code
*
******************************************************************************/
`include "define.vh"
`timescale 1ns/1ps

module FFT_IP(
    input   clk,
    input   rst_n,
    input   InValid,
    input   signed [`DATA_WIDTH-1:0]   FFTInRe,
    input   signed [`DATA_WIDTH-1:0]   FFTInIm,
    output  signed [`DATA_WIDTH-1:0]   BROutRe,
    output  signed [`DATA_WIDTH-1:0]   BROutIm,
    output  OutValid);

    logic signed [`DATA_WIDTH-1:0] SDFOutRe;
    logic signed [`DATA_WIDTH-1:0] SDFOutIm;
    logic FFT_OutValid;
    logic signed [`DATA_WIDTH*2-1:0] SDFOut;
    logic signed [`DATA_WIDTH*2-1:0] BROut; 

    assign SDFOut[`DATA_WIDTH*2-1 -: `DATA_WIDTH] = SDFOutRe;
    assign SDFOut[`DATA_WIDTH-1 -: `DATA_WIDTH] = SDFOutIm;
    assign BROutRe = BROut[`DATA_WIDTH*2-1 -: `DATA_WIDTH];
    assign BROutIm = BROut[`DATA_WIDTH-1 -: `DATA_WIDTH];

    SDF_FFT FFT_Unit(
        .clk(clk),
        .rst_n(rst_n),
        .InValid(InValid),
        .FFTInRe(FFTInRe),
        .FFTInIm(FFTInIm),
        .SDFOutRe(SDFOutRe),
        .SDFOutIm(SDFOutIm),
        .OutValid(FFT_OutValid));

    Reorder_Buffer Reorder_Unit(
        .clk(clk),
        .rst_n(rst_n),
        .InValid(FFT_OutValid),
        .SDFOut(SDFOut),
        .BROut(BROut),
        .OutValid(OutValid));

endmodule