/******************************************************************************
* Copyright (C) 2026 Marco
*
* File Name:    CORDIC_UF.sv
* Project:      [HW4] 2026 Spring DSP In VLSI @NTU <ICDA5003>
* Module:       CORDIC_UF
* Author:       Marco <harry2963753@gmail.com>
* Student ID:   M11407439
* Tool:         VCS & Verdi
* 
******************************************************************************/
`timescale 1ps/1ps
`include "define.vh"

typedef enum logic [1:0] {IDLE, PROCESSING, OUT} STATETPYE;

module CORDIC_UF(
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

    // REGISTER 
    logic signed [`THETA_W-1:0] Theta_r;
    logic signed [`THETA_W-1:0] Theta_a;
    logic signed [`DATA_W-1:0] XN_r;
    logic signed [`DATA_W-1:0] YN_r;
     logic Iter_cnt;

    // NET
    logic signed [`DATA_W-1:0] XN;
    logic signed [`DATA_W-1:0] YN;
    logic signed [`THETA_W-1:0] Theta;
    logic signed [`DATA_W-1:0] DX;
    logic signed [`DATA_W-1:0] DY;

    // LUT (ROM)
    logic signed [`THETA_W-1:0] Theta_e [0:`ITERATION-1];

    always_ff @(posedge clk or negedge rst_n) begin : FSM_FF
        if(!rst_n) state <= IDLE;
        else state <= next_state;
    end

    always_comb begin : FSM_COMB
        case(state)
            IDLE : next_state = (InValid)? PROCESSING : IDLE;
            PROCESSING : next_state = (Iter_cnt == `ITERATION/5-1)? OUT : PROCESSING;
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
            XN_r <= 0;
            YN_r <= 0;
            Theta_r <= 0;
            Theta_a <= 0;
        end
        else if(state == IDLE && InValid) begin
            if(InX < 0) begin
                XN_r <= -InX;
                YN_r <= -InY;
                Theta_a <= (InY >= 0)? `PI : `NEG_PI;
            end
            else begin
                XN_r <= InX;
                YN_r <= InY;
                Theta_a <= 0;
            end
            Theta_r <= 0;
        end
        else if(state == PROCESSING) begin
            XN_r <= XN;
            YN_r <= YN;
            Theta_r <= Theta;
        end
    end

    always_comb begin : ITERATION_UNFOLDING_LOGIC
        for(int i = 0; i<5; i++) begin
            if(i==0) begin
                // 先把位移邏輯做完，避免產生 Data Hazard
                DX = (YN_r >>> Iter_cnt*5+i);
                DY = (XN_r >>> Iter_cnt*5+i);
                if(YN_r[`DATA_W-1]) begin
                    XN = XN_r - DX;
                    YN = YN_r + DY;
                    Theta = Theta_r - Theta_e[Iter_cnt*5+i];                    
                end
                else begin
                    XN = XN_r + DX;
                    YN = YN_r - DY;
                    Theta = Theta_r + Theta_e[Iter_cnt*5+i];                      
                end
            end
            else begin
                // 先把位移邏輯做完，避免產生 Data Hazard
                DX = (YN >>> Iter_cnt*5+i);
                DY = (XN >>> Iter_cnt*5+i);
                if(YN[`DATA_W-1]) begin
                    XN = XN - DX;
                    YN = YN + DY;
                    Theta = Theta - Theta_e[Iter_cnt*5+i];                    
                end
                else begin
                    XN = XN + DX;
                    YN = YN - DY;
                    Theta = Theta + Theta_e[Iter_cnt*5+i];                      
                end                
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
            OutX <= XN_r;
            OutY <= YN_r;
            OutTheta <= Theta_r + Theta_a;
        end
        else begin
            OutX <= 0;
            OutY <= 0;
            OutTheta <= 0;
        end
    end

endmodule