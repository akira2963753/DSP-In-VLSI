/******************************************************************************
* Copyright (C) 2026 Marco
*
* File Name:    TESTED.sv
* Project:      [HW3] 2026 Spring DSP In VLSI @NTU <ICDA5003>
* Module:       TESTED
* Author:       Marco <harry2963753@gmail.com>
* Student ID:   M11407439
* Tool:         VCS & Verdi
* 
******************************************************************************/

`timescale  1ns/1ps
`include "../01_RTL/define.vh"

module TESTED();

    logic   clk;
    logic   rst_n;
    logic   IntpIn_valid;
    logic   [`IO_WIDTH-1:0] IntpIn;
    logic   [`MU_WIDTH-1:0] Mu;
    wire    [`IO_WIDTH-1:0] IntpOut;
    wire    IntpOut_valid;
    
    Interpolator DUT (.*);

    logic   [`IO_WIDTH-1:0] IntpIn_TEMP [0:`TESTCASE-1];
    logic   [`MU_WIDTH-1:0] Mu_TEMP [0:`MU_NUM-1];
    logic   [`IO_WIDTH-1:0] IntpOut_TEMP [0:`TESTCASE*`MU_NUM-1];
    logic   [`IO_WIDTH-1:0] IntpOut_GOLDEN [0:`TESTCASE*`MU_NUM-1];
    
    initial begin
        $readmemh({`Path, "x1_real_in.dat"}, IntpIn_TEMP);
        $readmemh({`Path, "mu_in.dat"}, Mu_TEMP);
        $readmemh({`Path, "golden_real.dat"}, IntpOut_GOLDEN);
    end

    always #(`CLK_PERIOD/2) clk = ~clk;

    initial begin
        RESET_ALL();
        @(negedge clk) rst_n = 0;
        @(negedge clk) rst_n = 1;
        INPUT_GEN();
        wait(!IntpOut_valid);
        CHECK_RESULT();
        WRITE_OUTPUT();
        #100 $finish;
    end

    initial begin
        wait(IntpOut_valid);
        for(int i=0; i<`TESTCASE*`MU_NUM; i++) begin
            @(negedge clk);
            IntpOut_TEMP[i] = IntpOut;
        end
    end

    task RESET_ALL;
        begin
            clk = 0;
            rst_n = 1;
            IntpIn_valid = 0;
            IntpIn = 0;
            Mu = 0;
        end
    endtask

    task INPUT_GEN;
        begin
            for(int i=0; i<`TESTCASE; i++) begin
                for(int j=0; j<`MU_NUM; j++) begin
                    @(negedge clk);
                    IntpIn_valid = 1;
                    IntpIn = IntpIn_TEMP[i];
                    Mu = Mu_TEMP[j];
                end
            end
            // 注意這裡要輸出最後一組 Mu 不然會算不出最後一組
            for(int j=0; j<`MU_NUM; j++) begin
                @(negedge clk);
                Mu = Mu_TEMP[j];
                IntpIn_valid = 0;
                IntpIn = 0;
            end
        end
    endtask

    task CHECK_RESULT;
        begin
            for(int i=0; i<`TESTCASE*`MU_NUM; i++) begin
                if(IntpOut_TEMP[i] !== IntpOut_GOLDEN[i]) begin
                    $display("========================================");
                    $display("               TEST FAILED              ");
                    $display("========================================");
                    $display("  Index    : %0d", i);
                    $display("  Output   : %h", IntpOut_TEMP[i]);
                    $display("  Expected : %h", IntpOut_GOLDEN[i]);
                    $display("========================================");
                    #10 $finish;
                end
            end
            $display("========================================");
            $display("           ALL TEST PASSED !!!          ");
            $display("========================================");
        end
    endtask

    task WRITE_OUTPUT;
        integer fd;
        begin
            fd = $fopen({`Path, "output.dat"}, "w");
            for(int i=0; i<`TESTCASE*`MU_NUM; i++) begin
                $fwrite(fd, "%h\n", IntpOut_TEMP[i]);
            end
            $fclose(fd);
            $display("Output written to output.dat");
        end
    endtask

    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0, TESTED);
        $fsdbDumpMDA;
    end
    
endmodule