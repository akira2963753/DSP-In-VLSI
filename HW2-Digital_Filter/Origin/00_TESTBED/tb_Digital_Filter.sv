/******************************************************************************
* Copyright (C) 2026 Marco
*
* File Name:    tb_Digital_Filter.v
* Project:      [HW2] 2026 Spring DSP In VLSI @NTU <ICDA5003>
* Module:       tb_Digital_Filter
* Author:       Marco <harry2963753@gmail.com>
* Student ID:   M11407439
* Tool:         VCS & Verdi
*
******************************************************************************/
`timescale 1ns/1ps
`define X_WIDTH     16    // FilterIn Width
`define Y_WIDTH     21    // FilterOut Width
`define X_NUM       144
`define CYCLE       1
`define SRC_PATH    "../00_TESTBED/src/"

module tb_Digital_Filter();

    logic clk;
    logic rst_n;
    logic signed [`X_WIDTH-1:0] FilterIn;
    logic ValidIn;
    logic signed [`Y_WIDTH-1:0] FilterOut;
    logic ValidOut;
    logic [7:0] OUTPUT_CNT;

    int i, j;
    integer output_file;
    Digital_Filter DUT(.*);

    logic signed [`X_WIDTH-1:0] IN_TEMP [0:`X_NUM-1];
    initial $readmemb({`SRC_PATH ,"input.dat"},IN_TEMP);

    always #(`CYCLE/2) clk = ~clk;

    initial begin
        // Reset ALL
        clk = 0; rst_n = 1; FilterIn = 0; ValidIn = 0; OUTPUT_CNT = 0;
        @(negedge clk) rst_n = 0;
        @(negedge clk) rst_n = 1;
        input_data();
        @(negedge clk);
        FilterIn = 0; ValidIn = 0;
        wait(!ValidOut);
        $display("Simulation Success !");
        #20 $finish;
    end

    initial begin
        #1000000 $display("Simulation Fail !");
        #20 $finish;
    end

    task input_data;
        begin
            @(negedge clk); // Delay
            for(i=0; i<`X_NUM; i=i+1) begin
                @(negedge clk);
                FilterIn = IN_TEMP[i];
                ValidIn = 1;
            end
        end
    endtask

    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0, tb_Digital_Filter);
        $fsdbDumpMDA;
    end

    initial begin
        output_file = $fopen({`SRC_PATH, "output.dat"}, "w");
        wait(ValidOut) begin
            for(j=0; j<`X_NUM; j=j+1) begin
                @(negedge clk);
                $fdisplay(output_file, "%0d", FilterOut);
                @(posedge clk) OUTPUT_CNT = OUTPUT_CNT + 1;
            end
        end
        $fclose(output_file);
        $display("Ending of Output File written");
    end

endmodule
