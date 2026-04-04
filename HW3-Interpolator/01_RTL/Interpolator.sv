/******************************************************************************
* Copyright (C) 2026 Marco
*
* File Name:    Interpolator.sv
* Project:      [HW3] 2026 Spring DSP In VLSI @NTU <ICDA5003>
* Module:       Interpolator
* Author:       Marco <harry2963753@gmail.com>
* Student ID:   M11407439
* Tool:         VCS & Verdi
* 
******************************************************************************/
`timescale 1ns/1ps

`include "define.vh"

import BF16_PKG::*; // 引入 BF16_PKG 以使用其中的函數和定義
typedef enum logic {IDLE, PROCESSING} STATETYPE; // 定義狀態

module Interpolator (
    input   clk,
    input   rst_n,
    input   IntpIn_valid,
    input   [`IO_WIDTH-1:0] IntpIn_Real,
    input   [`IO_WIDTH-1:0] IntpIn_Imag,
    input   [`MU_WIDTH-1:0] Mu,
    output  logic [`IO_WIDTH-1:0] IntpOut_Real,
    output  logic [`IO_WIDTH-1:0] IntpOut_Imag,
    output  logic IntpOut_valid
);
    // State Definition
    STATETYPE state, next_state;

    logic [4:0] cnt;
    logic [3:0] Sample_Pulse;
    logic pending;
    logic [`MU_WIDTH-1:0] Mu_Reg;
    logic [`IO_WIDTH-1:0] Real_Out, Imag_Out;

    Common_Logic Real_Part(
        .clk(clk),
        .rst_n(rst_n),
        .Sample_Pulse(Sample_Pulse),
        .state(state),
        .IntpIn(IntpIn_Real),
        .Mu_Reg(Mu_Reg),
        .IntpOut(Real_Out));

    Common_Logic Imag_Part(
        .clk(clk),
        .rst_n(rst_n),
        .Sample_Pulse(Sample_Pulse),
        .state(state),
        .IntpIn(IntpIn_Imag),
        .Mu_Reg(Mu_Reg),
        .IntpOut(Imag_Out));

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) Mu_Reg <= 0;
        else Mu_Reg <= Mu;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) state <= IDLE;
        else state <= next_state;
    end

    always_comb begin
        case(state)
            IDLE: next_state = (cnt==5'd31)? PROCESSING : IDLE;
            // 如果 IntpIn_Valid = 0，也必須要輸出完最後 8 組才可以結束
            PROCESSING: next_state = (IntpIn_valid || cnt!=5'd8)? PROCESSING : IDLE;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) cnt <= 0;
        else if(state==IDLE && IntpIn_valid) cnt <= cnt + 1;
        else if(state==PROCESSING && !IntpIn_valid) cnt <= cnt + 1;
        else cnt <= 0;
    end

    // 要轉回去 1 是因為這樣才能夠對齊第一組跟後面幾組 
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) Sample_Pulse <= 0;  
        else if(IntpIn_valid) Sample_Pulse <= (Sample_Pulse==4'd8)? 1 : Sample_Pulse + 1;
        else Sample_Pulse <= 0;
    end

    always_ff @(posedge clk or negedge rst_n) begin 
        if(!rst_n) pending <= 0;
        else pending <= (state==PROCESSING);
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            IntpOut_Real <= 0;
            IntpOut_Imag <= 0;
            IntpOut_valid <= 0;
        end
        else if(pending && state==PROCESSING) begin
            IntpOut_Real <= Real_Out;
            IntpOut_Imag <= Imag_Out;
            IntpOut_valid <= 1;
        end
        else begin
            IntpOut_Real <= 0;
            IntpOut_Imag <= 0;
            IntpOut_valid <= 0;
        end
    end

endmodule

module Common_Logic(
    input   clk,
    input   rst_n,
    input   [3:0] Sample_Pulse,
    input   STATETYPE state,
    input   [`MU_WIDTH-1:0] Mu_Reg,
    input   [`IO_WIDTH-1:0] IntpIn,
    output  logic [`IO_WIDTH-1:0] IntpOut);

    // Reg[3] = X(m-1), Reg[2] = X(m), Reg[1] = X(m+1), Reg[0] = X(m+2)
    logic [`IO_WIDTH-1:0] IntpIn_Reg [0:`NUM-1];
    logic [`IO_WIDTH-1:0] IntpIn_TEMP;

    logic [`IO_WIDTH-1:0] Shared;  // 0.5 * [X(m+2) + X(m-1)]
    logic [`IO_WIDTH-1:0] XM1_0_5; // 0.5 * X(m+1)
    logic [`IO_WIDTH-1:0] XM1_1_5; // 1.5 * X(m+1)
    logic [`IO_WIDTH-1:0] XM_0_5;  // 0.5 * X(m)
    logic [`IO_WIDTH-1:0] V2, V1, V0;
    logic [`IO_WIDTH-1:0] uV2;
    logic [`IO_WIDTH-1:0] uV2_V1;
    logic [`IO_WIDTH-1:0] uuV2_uV1;
    logic [`IO_WIDTH-1:0] uu_V2_uV1_V0;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(int i=0; i<`NUM; i++) IntpIn_Reg[i] <= 0;
        end
        else begin
            if(Sample_Pulse==4'd7) IntpIn_TEMP <= IntpIn;
            if(Sample_Pulse==4'd8) begin
                for(int i=0; i<`NUM; i++) begin   
                    if(i==0) IntpIn_Reg[i] <= IntpIn_TEMP;
                    else IntpIn_Reg[i] <= IntpIn_Reg[i-1];
                end
            end
        end
    end

    always_comb begin
        if(state == PROCESSING) begin
            // [X(m+2) + X(m-1)]
            Shared = BF16_ADD(IntpIn_Reg[0], IntpIn_Reg[3]);
            // 0.5 * [X(m+2) + X(m-1)]
            Shared = BF16_MUL(Shared, `HALF_MUL);
            // 0.5 * X(m+1)
            XM1_0_5 = BF16_MUL(IntpIn_Reg[1], `HALF_MUL); 
            // 1.5 * X(m+1)
            XM1_1_5 = BF16_ADD(XM1_0_5, IntpIn_Reg[1]);
            // 0.5 * X(m)
            XM_0_5 = BF16_MUL(IntpIn_Reg[2], `HALF_MUL); 
            // V2 = 0.5 * [X(m+2) + X(m-1)] - 0.5 * X(m+1) - 0.5 * X(m)
            V2 = BF16_ADD(Shared, {1'b1 ^ XM1_0_5[`IO_WIDTH-1], XM1_0_5[`IO_WIDTH-2:0]});
            V2 = BF16_ADD(V2, {1'b1 ^ XM_0_5[`IO_WIDTH-1], XM_0_5[`IO_WIDTH-2:0]});
            // V1 = 1.5 * X(m+1) - 0.5 * X(m) - 0.5 * [X(m+2) + X(m-1)]
            V1 = BF16_ADD({1'b1 ^ Shared[`IO_WIDTH-1], Shared[`IO_WIDTH-2:0]}, XM1_1_5);
            V1 = BF16_ADD(V1, {1'b1 ^ XM_0_5[`IO_WIDTH-1], XM_0_5[`IO_WIDTH-2:0]});
            // V0 = X(m)
            V0 = IntpIn_Reg[2];
            uV2 = BF16_MUL(V2, Mu_Reg);
            uV2_V1 = BF16_ADD(uV2, V1);
            uuV2_uV1 = BF16_MUL(uV2_V1, Mu_Reg);
            uu_V2_uV1_V0 = BF16_ADD(uuV2_uV1, V0);
        end
        else begin
            Shared = 0;
            XM1_0_5 = 0;
            XM1_1_5 = 0;
            XM_0_5 = 0;
            V2 = 0;
            V1 = 0;
            V0 = 0;
            uV2 = 0;
            uV2_V1 = 0;
            uuV2_uV1 = 0;
            uu_V2_uV1_V0 = 0;
        end
        IntpOut = uu_V2_uV1_V0;
    end

endmodule