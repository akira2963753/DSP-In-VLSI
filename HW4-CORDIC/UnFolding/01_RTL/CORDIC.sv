/******************************************************************************
* Copyright (C) 2026 Marco
*
* File Name:    CORDIC.sv
* Project:      [HW4] 2026 Spring DSP In VLSI @NTU <ICDA5003>
* Module:       CORDIC
* Author:       Marco <harry2963753@gmail.com>
* Student ID:   M11407439
* Tool:         VCS & Verdi
* Comment Opt:  Claude Code
*
******************************************************************************/
`timescale 1ps/1ps
`include "define.vh"

module CORDIC(
    input   clk,
    input   rst_n,
    input   InValid,
    input   signed  [`DATA_W-1:0]   InX,
    input   signed  [`DATA_W-1:0]   InY,
    output  logic   signed  [`DATA_W-1:0]   OutX,
    output  logic   signed  [`DATA_W-1:0]   OutY,
    output  logic   signed  [`THETA_W-1:0]  OutTheta,
    output  logic   OutValid
    );

    //============================================================
    // ------------------ Signal Declaration --------------------
    //============================================================

    // LUT
    logic signed [`THETA_W-1:0] Theta_e [0:`ITERATION-1];

    // Registers
    logic Valid [0:`PIPE_STAGE-1];
    logic signed [`DATA_W-1:0]  XN_r    [0:`PIPE_STAGE-1];
    logic signed [`DATA_W-1:0]  YN_r    [0:`PIPE_STAGE-1];
    logic signed [`THETA_W-1:0] Theta_r [0:`PIPE_STAGE-1];
    logic signed [`THETA_W-1:0] Theta_A [0:`PIPE_STAGE-1];

    // Combinational
    logic signed [`DATA_W-1:0]  XN    [0:`PIPE_STAGE-1];
    logic signed [`DATA_W-1:0]  YN    [0:`PIPE_STAGE-1];
    logic signed [`DATA_W-1:0]  DX    [0:`PIPE_STAGE-1];
    logic signed [`DATA_W-1:0]  DY    [0:`PIPE_STAGE-1];
    logic signed [`THETA_W-1:0] Theta [0:`PIPE_STAGE-1];

    //============================================================
    // ------------------- Initial Stage -----------------------
    //============================================================

    always_ff @(posedge clk or negedge rst_n) begin : INITIAL_STAGE
        if(!rst_n) begin
            Valid[0] <= 0;
            XN_r[0] <= 0;
            YN_r[0] <= 0;
            Theta_r[0] <= 0;
            Theta_A[0] <= 0;
        end
        else begin
            Valid[0] <= InValid;
            Theta_r[0] <= 0;
            if(InValid) begin
                if(InX < 0) begin
                    XN_r[0] <= -InX;
                    YN_r[0] <= -InY;
                    Theta_A[0] <= (InY >= 0) ? `PI : `NEG_PI;
                end
                else begin
                    XN_r[0] <= InX;
                    YN_r[0] <= InY;
                    Theta_A[0] <= 0;
                end
            end
            else begin  // 如果 InValid = 0，則 XN_r, YN_r, Theta_A 都歸 0
                XN_r[0] <= 0;
                YN_r[0] <= 0;
                Theta_A[0] <= 0;
            end
        end
    end

    //============================================================
    // ----------- Iteration Stages & Pipeline Registers --------
    //============================================================

    // 把重複寫的 Pipelined 跟 Unfolding 用 Generate 打包起來，實現可參數化
    localparam J = `ITERATION / `PIPE_STAGE; // 一定要整除
    genvar s;
    generate
        for(s = 0; s < `PIPE_STAGE; s++) begin : PIPE_STAGE_GEN
            always_comb begin
                XN[s] = XN_r[s];
                YN[s] = YN_r[s];
                Theta[s] = Theta_r[s];
                for(int i = 0; i < J; i++) begin
                    DX[s] = YN[s] >>> (s*J + i);
                    DY[s] = XN[s] >>> (s*J + i);
                    if(YN[s][`DATA_W-1]) begin  // YN 為負, mu = +1
                        XN[s] = XN[s] - DX[s];
                        YN[s] = YN[s] + DY[s];
                        Theta[s] = Theta[s] - Theta_e[s*J + i];
                    end
                    else begin  // YN 為正, mu = -1
                        XN[s] = XN[s] + DX[s];
                        YN[s] = YN[s] - DY[s];
                        Theta[s] = Theta[s] + Theta_e[s*J + i];
                    end
                end
            end
            // Pipeline 傳遞
            if(s < `PIPE_STAGE-1) begin : PIPELINE_REG
                always_ff @(posedge clk or negedge rst_n) begin
                    if(!rst_n) begin
                        Valid[s+1] <= 0;
                        XN_r[s+1] <= 0;
                        YN_r[s+1] <= 0;
                        Theta_r[s+1] <= 0;
                        Theta_A[s+1] <= 0;
                    end
                    else begin
                        Valid[s+1] <= Valid[s];
                        XN_r[s+1] <= XN[s];
                        YN_r[s+1] <= YN[s];
                        Theta_r[s+1] <= Theta[s];
                        Theta_A[s+1] <= Theta_A[s];
                    end
                end
            end
        end
    endgenerate

    //============================================================
    // ------------------- Output Stage ------------------------
    //============================================================

    always_ff @(posedge clk or negedge rst_n) begin : OUTPUT_STAGE
        if(!rst_n) begin
            OutValid <= 0;
            OutX <= 0;
            OutY <= 0;
            OutTheta <= 0;
        end
        else begin
            OutValid <= Valid[`PIPE_STAGE-1];
            if(Valid[`PIPE_STAGE-1]) begin
                OutX <= XN[`PIPE_STAGE-1];
                OutY <= YN[`PIPE_STAGE-1];
                OutTheta <= Theta[`PIPE_STAGE-1] + Theta_A[`PIPE_STAGE-1];
            end
            // 這裡可以不用寫歸 0，畢竟 OutValid = 1 才會 Capture，減少位元翻轉次數有助於降低功耗
        end
    end

    //============================================================
    // ----------------------- LUT ------------------------------
    //============================================================

    always_comb begin : THETA_E_LUT
        Theta_e[0]  = `THETA_W'b0_00_1100100100;
        Theta_e[1]  = `THETA_W'b0_00_0111011011;
        Theta_e[2]  = `THETA_W'b0_00_0011111011;
        Theta_e[3]  = `THETA_W'b0_00_0001111111;
        Theta_e[4]  = `THETA_W'b0_00_0001000000;
        Theta_e[5]  = `THETA_W'b0_00_0000100000;
        Theta_e[6]  = `THETA_W'b0_00_0000010000;
        Theta_e[7]  = `THETA_W'b0_00_0000001000;
        Theta_e[8]  = `THETA_W'b0_00_0000000100;
        Theta_e[9]  = `THETA_W'b0_00_0000000010;
        Theta_e[10] = `THETA_W'b0_00_0000000001;
        Theta_e[11] = `THETA_W'b0_00_0000000000;
    end

endmodule
