/******************************************************************************
* Copyright (C) 2026 Marco
*
* File Name:    TESTBED.sv
* Project:      [HW4] 2026 Spring DSP In VLSI @NTU <ICDA5003>
* Module:       TESTBED
* Author:       Marco <harry2963753@gmail.com>
* Student ID:   M11407439
* Tool:         VCS & Verdi
* Comment Opt:  Claude Code
*
******************************************************************************/

`timescale 1ns/10ps
`include "../01_RTL/define.vh"

module TESTBED();

    //============================================================
    // ------------------- Simulation Mode ----------------------
    //============================================================

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

    //============================================================
    // ------------------ Signal Declaration --------------------
    //============================================================

    logic   clk;
    logic   rst_n;
    logic   InValid;
    logic   signed  [`DATA_W-1:0]   InX;
    logic   signed  [`DATA_W-1:0]   InY;

    wire    signed  [`DATA_W-1:0]   OutX;
    wire    signed  [`DATA_W-1:0]   OutY;
    wire    signed  [`THETA_W-1:0]  OutTheta;
    wire    OutValid;
    wire    signed  [`MAG_W-1:0]    Magnitude;

    always #(`CLOCK_DIV) clk = ~clk;

    //============================================================
    // ------------------ DUT Instantiation ---------------------
    //============================================================

    CORDIC DUT (.*);

    //============================================================
    // ------------------ Test Data Arrays ----------------------
    //============================================================

    logic signed [`DATA_W-1:0]  X_TEMP [0:`NUM_TEST-1];
    logic signed [`DATA_W-1:0]  Y_TEMP [0:`NUM_TEST-1];
    logic signed [`THETA_W-1:0] THETA_TEMP [0:`NUM_TEST-1];
    logic signed [`MAG_W-1:0]  MAGNITUDE_TEMP [0:`NUM_TEST-1];

    logic signed [`THETA_W-1:0] THETA_GOLD [0:`NUM_TEST-1];
    logic signed [`MAG_W-1:0]  MAGNITUDE_GOLD [0:`NUM_TEST-1];

    logic [3:0] out_cnt;

    //============================================================
    // --------------- Data Load & Golden Compute ---------------
    //============================================================

    initial begin
        $readmemb({`PATH,"InX.dat"}, X_TEMP);
        $readmemb({`PATH,"InY.dat"}, Y_TEMP);
        COMPUTE_GOLDEN();
    end

    //============================================================
    // ---------------------- FSDB Dump -------------------------
    //============================================================

    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0, TESTBED);
        $fsdbDumpMDA;
    end

    //============================================================
    // ------------------- Timing Watchdog ----------------------
    //============================================================

    initial begin
        #100000;
        $display("========================================");
        $display("        TEST FAILED (OUT OF TIME)       ");
        $display("========================================");
        #10 $finish;
    end

    //============================================================
    // ------------------ Main Test Stimulus --------------------
    //============================================================

    initial begin
        RESET_ALL();
        repeat(2) @(negedge clk) rst_n = ~rst_n; 
        INPUT_GEN();
        // 確保每一筆 OutTheta 都有被 always block 捕捉到
        repeat(5) @(negedge clk); 
        $writememh({`PATH,"OutTheta.dat"}, THETA_TEMP);
        $writememh({`PATH,"Magnitude.dat"}, MAGNITUDE_TEMP);
        GOLDEN_CHECK();
        #100 $finish;
    end

    //============================================================
    // ------------------- Output Capture -----------------------
    //============================================================

    always @(negedge clk or negedge rst_n) begin
        if(!rst_n) out_cnt <= 0;
        else if(OutValid) begin
            THETA_TEMP[out_cnt] <= OutTheta;
            MAGNITUDE_TEMP[out_cnt] <= Magnitude;
            out_cnt <= out_cnt + 1;
        end
        else;
    end

    //============================================================
    // ------------------------ Tasks ---------------------------
    //============================================================

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
            for(int i = 0; i < `NUM_TEST; i++) begin
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

    // 如果 task 會執行很多次並且有 local 變數，記得加 Automatic
    task COMPUTE_GOLDEN;
        logic signed [`DATA_W-1:0]  gx, gy, dx, dy;
        logic signed [`THETA_W-1:0] gtheta, gtheta_a;
        logic signed [`THETA_W-1:0] lut [0:`ITERATION-1];
        logic signed [`MAG_W-1:0]   ga, gb;
        begin
            lut[0]  = `THETA_W'b0_00_1100100100;
            lut[1]  = `THETA_W'b0_00_0111011011;
            lut[2]  = `THETA_W'b0_00_0011111011;
            lut[3]  = `THETA_W'b0_00_0001111111;
            lut[4]  = `THETA_W'b0_00_0001000000;
            lut[5]  = `THETA_W'b0_00_0000100000;
            lut[6]  = `THETA_W'b0_00_0000010000;
            lut[7]  = `THETA_W'b0_00_0000001000;
            lut[8]  = `THETA_W'b0_00_0000000100;
            lut[9]  = `THETA_W'b0_00_0000000010;
            lut[10] = `THETA_W'b0_00_0000000001;
            lut[11] = `THETA_W'b0_00_0000000000;

            for(int i = 0; i < `NUM_TEST; i++) begin
                if(X_TEMP[i] < 0) begin
                    gx = -X_TEMP[i];
                    gy = -Y_TEMP[i];
                    gtheta_a = (Y_TEMP[i] >= 0) ? `PI : `NEG_PI;
                end else begin
                    gx = X_TEMP[i];
                    gy = Y_TEMP[i];
                    gtheta_a = 0;
                end
                gtheta = 0;

                for(int j = 0; j < `ITERATION; j++) begin
                    dx = gy >>> j;
                    dy = gx >>> j;
                    if(gy[`DATA_W-1]) begin  // YN 負，mu = +1
                        gx = gx - dx;
                        gy = gy + dy;
                        gtheta = gtheta - lut[j];
                    end else begin           // YN 正，mu = -1
                        gx = gx + dx;
                        gy = gy - dy;
                        gtheta = gtheta + lut[j];
                    end
                end

                ga = (gx >>> 1) + (gx >>> 3);
                gb = (gx >>> 6) + (gx >>> 9);

                // Write Into Golden Temp
                MAGNITUDE_GOLD[i] = ga - gb;
                THETA_GOLD[i] = gtheta + gtheta_a;
            end
        end
    endtask

    task GOLDEN_CHECK;
        begin
            for(int i = 0; i < `NUM_TEST; i++) begin
                if(THETA_TEMP[i] !== THETA_GOLD[i] || MAGNITUDE_TEMP[i] !== MAGNITUDE_GOLD[i]) begin
                    $display("========================================");
                    $display("           TEST FAILED [%0d]            ", i);
                    $display("  Theta : %0d (got) vs %0d (gold)", THETA_TEMP[i], THETA_GOLD[i]);
                    $display("  Mag   : %0d (got) vs %0d (gold)", MAGNITUDE_TEMP[i], MAGNITUDE_GOLD[i]);
                    $display("========================================");
                    #10 $finish;
                end
            end
            $display("========================================");
            $display("            ALL PASS !!!                ");
            $display("========================================");
        end
    endtask

endmodule
