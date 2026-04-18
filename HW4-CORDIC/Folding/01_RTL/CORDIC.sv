/******************************************************************************
* Copyright (C) 2026 Marco
*
* File Name:    CORDIC.sv
* Project:      [HW4] 2026 Spring DSP In VLSI @NTU <ICDA5003>
* Module:       CORDIC
* Author:       Marco <harry2963753@gmail.com>
* Student ID:   M11407439
* Tool:         VCS & Verdi
* 
******************************************************************************/
`timescale 1ps/1ps
`include "define.vh"

typedef enum logic [1:0] {IDLE, PROCESSING, OUT} STATETPYE;

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

    STATETPYE state, next_state;

    logic [`ITER_CNT_W-1:0] Iter_cnt;
    logic signed [`THETA_W-1:0] Theta;
    logic signed [`THETA_W-1:0] Theta_a;
    logic signed [`THETA_W-1:0] Theta_e [0:`ITERATION-1];
    logic signed [`DATA_W-1:0] XN;
    logic signed [`DATA_W-1:0] YN;

    always_ff @(posedge clk or negedge rst_n) begin : FSM_FF
        if(!rst_n) state <= IDLE;
        else state <= next_state;
    end

    always_comb begin : FSM_COMB
        case(state)
            IDLE : next_state = (InValid)? PROCESSING : IDLE;
            PROCESSING : next_state = (Iter_cnt == `ITERATION-1)? OUT : PROCESSING;
            OUT : next_state = IDLE;
            default : next_state = IDLE;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin : ITER_CNT
        if(!rst_n) Iter_cnt <= 0;
        else if(state == PROCESSING) Iter_cnt <= Iter_cnt + 1;
        else Iter_cnt <= 0;
    end

    always_ff @(posedge clk or negedge rst_n) begin : CORDIC_DATAPATH
        if(!rst_n) begin
            XN <= 0;
            YN <= 0;
            Theta   <= 0;
            Theta_a <= 0;
        end
        else if(state == IDLE && InValid) begin
            if(InX < 0) begin
                XN <= -InX;
                YN <= -InY;
                Theta_a <= (InY >= 0)? `PI : `NEG_PI;
            end
            else begin
                XN <= InX;
                YN <= InY;
                Theta_a <= 0;
            end
            Theta <= 0;
        end
        else if(state == PROCESSING) begin
            if(YN[`DATA_W-1] == 1'b1) begin // YN 為負, Mu 為正
                XN <= XN - (YN >>> Iter_cnt);
                YN <= YN + (XN >>> Iter_cnt);
                Theta <= Theta - Theta_e[Iter_cnt];
            end
            else begin  // YN 為正, Mu 為負
                XN <= XN + (YN >>> Iter_cnt);
                YN <= YN - (XN >>> Iter_cnt);
                Theta <= Theta + Theta_e[Iter_cnt];
            end
        end
    end

    always_comb begin : THETA_E_LUT
        Theta_e[0] = `THETA_W'b0_00_11001001;  
        Theta_e[1] = `THETA_W'b0_00_01110111;  
        Theta_e[2] = `THETA_W'b0_00_00111111; 
        Theta_e[3] = `THETA_W'b0_00_00100000; 
        Theta_e[4] = `THETA_W'b0_00_00010000; 
        Theta_e[5] = `THETA_W'b0_00_00001000;
        Theta_e[6] = `THETA_W'b0_00_00000100;
        Theta_e[7] = `THETA_W'b0_00_00000010;
        Theta_e[8] = `THETA_W'b0_00_00000001;
        Theta_e[9] = `THETA_W'b0_00_00000000;
    end

    always_ff @(posedge clk) OutValid <= (state == OUT);

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin 
            OutX <= 0;
            OutY <= 0;
            OutTheta <= 0;
        end 
        else if(state==OUT) begin
            OutX <= XN;
            OutY <= YN;
            OutTheta <= Theta + Theta_a;
        end
        else begin
            OutX <= 0;
            OutY <= 0;
            OutTheta <= 0;
        end
    end

endmodule