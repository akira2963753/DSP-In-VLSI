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
    `else
        initial begin
            $display("========================================");
            $display("       BEHAVIORAL SIMULATION START      ");
            $display("========================================");
        end    
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
    wire    signed  [`MAG_W-1:0]    Magnitude;

    always #(`CLOCK_DIV) clk = ~clk;

    // DUT Instantiation
    CORDIC DUT (.*);

    logic signed [`DATA_W-1:0]  X_TEMP [0:`ITERATION-1];
    logic signed [`DATA_W-1:0]  Y_TEMP [0:`ITERATION-1];
    logic signed [`THETA_W-1:0] THETA_TEMP [0:`ITERATION-1];
    logic signed [`MAG_W-1:0]  MAGNITUDE_TEMP [0:`ITERATION-1];
    logic [3:0] out_cnt;

    initial begin
        $readmemb({`PATH,"InX.dat"}, X_TEMP);
        $readmemb({`PATH,"InY.dat"}, Y_TEMP);
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
        repeat(5) @(negedge clk);  // 確保每一筆 OutTheta 都有被 always block 捕捉到
        $writememh({`PATH,"OutTheta.dat"}, THETA_TEMP);
        $writememh({`PATH,"Magnitude.dat"}, MAGNITUDE_TEMP);
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
            MAGNITUDE_TEMP[out_cnt] <= Magnitude;
            out_cnt <= out_cnt + 1;            
        end
        else;
    end

    task RESET_ALL;
        begin
            clk = 0;
            rst_n = 1;
            InValid = 0;
            InX = 0;
            InY = 0;
        end
    endtask
    
    task INPUT_GEN;
        begin
            for(int i = 0; i < `ITERATION; i++) begin
                @(negedge clk);
                InValid = 1;
                InX = X_TEMP[i];
                InY = Y_TEMP[i];
                @(negedge clk); // 2 個 Cycle 送一次輸入
                InValid = 0;
                InX = 0;
                InY = 0; 
            end
            InValid = 0;
            InX = 0;
            InY = 0;
        end
    endtask

endmodule
