/******************************************************************************
* Copyright (C) 2026 Marco
*
* File Name:    TESTBED.sv
* Project:      [HW3] 2026 Spring DSP In VLSI @NTU <ICDA5003>
* Module:       TESTBED
* Author:       Marco <harry2963753@gmail.com>
* Student ID:   M11407439
* Tool:         VCS & Verdi
* 
******************************************************************************/

`timescale  1ns/1ps
`include "../01_RTL/define.vh"

module TESTBED();

    `ifdef GATE_SIM
        initial begin
            $display("========================================");
            $display("       GATE-LEVEL SIMULATION START      ");
            $display("========================================");        
        end

        // 03_GATESIM 
        initial $sdf_annotate("../02_SYN/Netlist/Interpolator.sdf", DUT);

    `endif

    logic   clk;
    logic   rst_n;
    logic   IntpIn_valid;
    logic   [`IO_WIDTH-1:0] IntpIn_Real;
    logic   [`IO_WIDTH-1:0] IntpIn_Imag;
    logic   [`MU_WIDTH-1:0] Mu;
    wire    [`IO_WIDTH-1:0] IntpOut_Real;
    wire    [`IO_WIDTH-1:0] IntpOut_Imag;
    wire    IntpOut_valid;
    
    Interpolator DUT (.*);

    logic   [`MU_WIDTH-1:0] Mu_TEMP [0:`MU_NUM-1];
    logic   [`IO_WIDTH-1:0] IntpIn_Real_TEMP [0:`TESTCASE-1];
    logic   [`IO_WIDTH-1:0] IntpOut_Real_TEMP [0:(`TESTCASE-2)*`MU_NUM-1];  
    logic   [`IO_WIDTH-1:0] IntpOut_Real_GOLDEN [0:(`TESTCASE-2)*`MU_NUM-1]; 
    logic   [`IO_WIDTH-1:0] IntpIn_Imag_TEMP [0:`TESTCASE-1];
    logic   [`IO_WIDTH-1:0] IntpOut_Imag_TEMP [0:(`TESTCASE-2)*`MU_NUM-1];  
    logic   [`IO_WIDTH-1:0] IntpOut_Imag_GOLDEN [0:(`TESTCASE-2)*`MU_NUM-1];
    
    initial begin
        $readmemh({`Path, "mu_in.dat"}, Mu_TEMP);
        $readmemh({`Path, "x1_real_in.dat"}, IntpIn_Real_TEMP);
        $readmemh({`Path, "golden_real.dat"}, IntpOut_Real_GOLDEN);
        $readmemh({`Path, "x1_imag_in.dat"}, IntpIn_Imag_TEMP);
        $readmemh({`Path, "golden_imag.dat"}, IntpOut_Imag_GOLDEN);
    end

    // Clock Generation
    always #(`CLK_DIV2) clk = ~clk;

    // Test Sequence
    initial begin
        // Initialize and Reset
        RESET_ALL();

        // Reset pulse
        repeat(2) @(negedge clk) rst_n = ~rst_n;
        
        // Generate input and check output
        INPUT_GEN(); 
        wait(!IntpOut_valid);   
        CHECK_RESULT();       

        // Write output to file for further analysis
        WRITE_OUTPUT();    
        #100 $finish;      
    end

    // Capture output for checking
    initial begin
        wait(IntpOut_valid);
        for(int i=0; i<(`TESTCASE-2)*`MU_NUM; i++) begin
            @(negedge clk);
            IntpOut_Real_TEMP[i] = IntpOut_Real;
            IntpOut_Imag_TEMP[i] = IntpOut_Imag;
        end
    end

    // Timing WatchDog
    initial begin
        #100000;
        $display("========================================");
        $display("        TEST FAILED (OUT OF TIME)       ");
        $display("========================================");
        #10 $finish;
    end

    // Tasks For Test Sequence
    task RESET_ALL;
        begin
            clk = 0;
            rst_n = 1;
            IntpIn_valid = 0;
            IntpIn_Real = 0;
            IntpIn_Imag = 0;
            Mu = 0;
        end
    endtask

    task INPUT_GEN;
        begin
            for(int i=0; i<`TESTCASE; i++) begin
                for(int j=0; j<`MU_NUM; j++) begin
                    @(negedge clk);
                    IntpIn_valid = 1;
                    IntpIn_Real = IntpIn_Real_TEMP[i];
                    IntpIn_Imag = IntpIn_Imag_TEMP[i];
                    Mu = Mu_TEMP[j];
                end
            end
            // 注意這裡還是要輸出最後一組 Mu 因為要算最後一組輸出
            for(int j=0; j<`MU_NUM; j++) begin
                @(negedge clk);
                Mu = Mu_TEMP[j];
                IntpIn_valid = 0;
                IntpIn_Real = 0;
                IntpIn_Imag = 0;
            end
        end
    endtask

    task CHECK_RESULT;
        begin
            for(int i=0; i<(`TESTCASE-2)*`MU_NUM; i++) begin
                if(IntpOut_Real_TEMP[i] !== IntpOut_Real_GOLDEN[i]) begin
                    $display("========================================");
                    $display("           REAL TEST FAILED             ");
                    $display("========================================");
                    $display("  Index    : %0d", i);
                    $display("  Output   : %h", IntpOut_Real_TEMP[i]);
                    $display("  Expected : %h", IntpOut_Real_GOLDEN[i]);
                    $display("========================================");
                    #20 $finish;
                end
            end
            for(int i=0; i<(`TESTCASE-2)*`MU_NUM; i++) begin
                if(IntpOut_Imag_TEMP[i] !== IntpOut_Imag_GOLDEN[i]) begin
                    $display("========================================");
                    $display("           IMAG TEST FAILED             ");
                    $display("========================================");
                    $display("  Index    : %0d", i);
                    $display("  Output   : %h", IntpOut_Imag_TEMP[i]);
                    $display("  Expected : %h", IntpOut_Imag_GOLDEN[i]);
                    $display("========================================");
                    #20 $finish;
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
            fd = $fopen({`Path, "output_real.dat"}, "w");
            for(int i=0; i<(`TESTCASE-2)*`MU_NUM; i++) begin
                $fwrite(fd, "%h\n", IntpOut_Real_TEMP[i]);
            end
            $fclose(fd);
            fd = $fopen({`Path, "output_imag.dat"}, "w");
            for(int i=0; i<(`TESTCASE-2)*`MU_NUM; i++) begin
                $fwrite(fd, "%h\n", IntpOut_Imag_TEMP[i]);
            end
            $fclose(fd);
            $display("========================================");
            $display("    Output written to output_real.dat   ");
            $display("    Output written to output_imag.dat   ");
            $display("========================================");
        end
    endtask

    // Waveform Dump (fsdb)
    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0, TESTBED);
        $fsdbDumpMDA;
    end
    
    // Property Setting for Assertion
    property output_clear; // 當 IntpOut_valid 從 1 跌到 0 的時候，下一個 Cycle 輸出應該被清零
          @(posedge clk) $fell(IntpOut_valid) |=> (IntpOut_Real === '0) && (IntpOut_Imag === '0);
    endproperty

    assert property (output_clear);

endmodule