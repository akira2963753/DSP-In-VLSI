/******************************************************************************
* Copyright (C) 2026 Marco
*
* File Name:    Reorder_Buffer.sv
* Project:      [HW5] 2026 Spring DSP In VLSI @NTU <ICDA5003>
* Module:       Reorder_Buffer
* Author:       Marco <harry2963753@gmail.com>
* Student ID:   M11407439
* Tool:         VCS & Verdi
* Comment Opt:  Claude Code
*
******************************************************************************/
`include "define.vh"
`timescale 1ps/1ps

module Reorder_Buffer (
    input   clk,
    input   rst_n,
    input   InValid,
    input   [`DATA_WIDTH*2-1:0]   SDFOut,
    output  logic   [`DATA_WIDTH*2-1:0]   BROut,
    output  logic   OutValid);

    // Synchronous Read SRAM Parameter
    logic [`DATA_WIDTH*2-1:0] BankA [0:`NUM-1];
    logic [`DATA_WIDTH*2-1:0] BankB [0:`NUM-1];
    logic [`ADDR_WIDTH-1:0] Addr_w;
    logic [`ADDR_WIDTH-1:0] Addr_r;
    logic BankA_w, BankB_w;
    logic Bank_sel;

    // Control Signal & Counter
    logic [`CNT_WIDTH-1:0] idx_cnt;
    logic Rd_en;

    assign Addr_w = {idx_cnt[0], idx_cnt[1], idx_cnt[2], idx_cnt[3], idx_cnt[4]};
    assign BankA_w = InValid && (!Bank_sel); 
    assign BankB_w = InValid && (Bank_sel);

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            idx_cnt <= 0;
            Bank_sel <= 0;
            Rd_en <= 0;
        end
        else if(InValid) begin
            idx_cnt <= idx_cnt + 1;
            if (idx_cnt == `NUM-1) begin
                Bank_sel <= ~Bank_sel;
                Rd_en <= 1; // Need to Read Signal
            end 
        end
        else begin
            idx_cnt <= 0; // If InValid = 0, Memory Stop W
            Rd_en <= (Addr_r==`NUM-1)? 0 : Rd_en; // Wait the reading finish 
        end
    end

    // BankA & BankB Memory
    always_ff @(posedge clk) begin
        // Write into BankA Memory
        if(BankA_w) BankA[Addr_w] <= SDFOut;
        // Write into BankB Memory
        if(BankB_w) BankB[Addr_w] <= SDFOut;
        // Select the Read Memory between Bank A and B
        BROut <= (Bank_sel)? BankA[Addr_r] : BankB[Addr_r];
    end

    // Synchronous Read SRAM Read Address would be prepared in last clock
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin 
            OutValid <= 0;
            Addr_r <= 0;
        end
        else begin 
            OutValid <= Rd_en;
            Addr_r <= (Rd_en)? Addr_r + 1 : 0;
        end
    end

endmodule