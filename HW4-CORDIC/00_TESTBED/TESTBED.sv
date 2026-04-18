/******************************************************************************
* Copyright (C) 2026 Marco
*
* File Name:    TESTBED.sv
* Project:      [HW4] 2026 Spring DSP In VLSI @NTU <ICDA5003>
* Module:       TESTBED
* Author:       Marco <harry2963753@gmail.com>
* Student ID:   M11407439
* Tool:         VCS & Verdi
* 
******************************************************************************/

`timescale 1ns/10ps
`include "../01_RTL/define.vh"

module TESTBED();

    `ifdef GATE_SIM
        initial begin
            $display("========================================");
            $display("       GATE-LEVEL SIMULATION START      ");
            $display("========================================");
        end

        initial $sdf_annotate("../02_SYN/Netlist/CORDIC.sdf", DUT);
    `endif

    // Inputs
    logic   clk;
    logic   rst_n;
    logic   InValid;
    logic   signed  [`DATA_W-1:0]   InX;
    logic   signed  [`DATA_W-1:0]   InY;

    // Outputs
    wire    signed  [`DATA_W-1:0]   OutX;
    wire    signed  [`DATA_W-1:0]   OutY;
    wire    signed  [`THETA_W-1:0]  OutTheta;
    wire    OutValid;

    always #(`CLOCK_PERIOD/2) clk = ~clk;

    // DUT Instantiation
    `ifdef UNFOLDING
        CORDIC_UF DUT (.*);
        initial begin
            $display("========================================");
            $display("     LOAD : CORDIC UNFLODING DESIGN     ");
            $display("========================================");
        end
    `else 
        CORDIC DUT (.*);
        initial begin
            $display("========================================");
            $display("      LOAD : CORDIC FLODING DESIGN      ");
            $display("========================================");
        end
    `endif

    logic signed [`DATA_W-1:0]  X_TEMP [0:`ITERATION-1];
    logic signed [`DATA_W-1:0]  Y_TEMP [0:`ITERATION-1];
    logic signed [`THETA_W-1:0] THETA_GOLD [0:`ITERATION-1];
    logic signed [`THETA_W-1:0] THETA_TEMP [0:`ITERATION-1];
    logic [3:0] out_cnt;

    initial begin
        $readmemb({`PATH,"InX.dat"}, X_TEMP);
        $readmemb({`PATH,"InY.dat"}, Y_TEMP);
        $readmemb({`PATH,"OutTheta.dat"}, THETA_GOLD);
    end

    // FSDB Dump
    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0, TESTBED);
        $fsdbDumpMDA;
    end

    // Timing Watchdog
    initial begin
        #100000;
        $display("========================================");
        $display("        TEST FAILED (OUT OF TIME)       ");
        $display("========================================");
        #10 $finish;
    end

    // Test Stimulus
    initial begin
        RESET_ALL();
        repeat(2) @(negedge clk) rst_n = ~rst_n;  // Generate reset pulse
        INPUT_GEN();
        repeat(2) @(negedge clk);  // 等最後一筆 OutTheta 被 always block 捕捉到
        $writememb({`PATH,"OutTheta.dat"}, THETA_TEMP);
        $display("========================================");
        $display("             SIMULATION END !           ");
        $display("========================================");
        #100 $finish;
    end

    // Capture output theta values for comparison
    always @(negedge clk or negedge rst_n) begin
        if(!rst_n) out_cnt <= 0;
        else if(OutValid) begin
            THETA_TEMP[out_cnt] <= OutTheta;
            out_cnt <= out_cnt + 1;            
        end
        else;
    end

    task RESET_ALL;
        begin
            clk     = 0;
            rst_n   = 1;
            InValid = 0;
            InX     = 0;
            InY     = 0;
        end
    endtask
    
    task INPUT_GEN;
        begin
            for(int i = 0; i < `ITERATION; i++) begin
                @(negedge clk);
                InValid = 1;
                InX = X_TEMP[i];
                InY = Y_TEMP[i]; 
                `ifdef UNFOLDING
                    repeat(2) @(negedge clk); // 3 個 Cycle 送一次輸入
                `else 
                    repeat(11) @(negedge clk); // 12 個 Cycle 送一次輸入
                `endif
            end
            InValid = 0;
            InX = 0;
            InY = 0;
        end
    endtask

endmodule
