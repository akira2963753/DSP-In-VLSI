/******************************************************************************
* Copyright (C) 2026 Marco
*
* File Name:    Digital_Filter_Parallel.v
* Project:      [HW2] 2026 Spring DSP In VLSI @NTU <ICDA5003>
* Module:       Digital_Filter_Parallel
* Author:       Marco <harry2963753@gmail.com>
* Student ID:   M11407439
* Tool:         VCS & Verdi
* 
******************************************************************************/

`timescale 1ns/1ps

`define X_WIDTH     16    // FilterIn Width
`define Y_WIDTH     21    // FilterOut Width
`define X_NUM       144
`define X_NUM_P     `X_NUM/2

module tb_Digital_Filter_Parallel;

    // DUT Signals
    reg                                 clk;
    reg                                 rst_n;
    reg     signed    [`X_WIDTH-1:0]    FilterIn0;
    reg     signed    [`X_WIDTH-1:0]    FilterIn1;
    reg                                 ValidIn;
    wire    signed    [`Y_WIDTH-1:0]    FilterOut0;
    wire    signed    [`Y_WIDTH-1:0]    FilterOut1;
    wire                                ValidOut;

    integer i,j;
    integer output_file;
    Digital_Filter_Parallel DUT(.*);

    reg signed [`X_WIDTH-1:0] IN_TEMP [0:`X_NUM-1];
    reg [7:0] OUTPUT_CNT0;
    reg [7:0] OUTPUT_CNT1;

    initial $readmemb("../RTL/src/input.dat",IN_TEMP);
    always #5 clk = ~clk;

    initial begin
        // Reset ALL
        clk = 0; rst_n = 1; FilterIn0 = 0; FilterIn1 = 0; ValidIn = 0;
        OUTPUT_CNT0 = 0; OUTPUT_CNT1 = 0;
        @(negedge clk) rst_n = 0;
        @(negedge clk) rst_n = 1;
        input_data();
        @(negedge clk);
        FilterIn0 = 0; FilterIn1 = 0; ValidIn = 0;
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
            for(i=0; i<`X_NUM; i=i+2) begin
                @(negedge clk);
                FilterIn0 = IN_TEMP[i];
                FilterIn1 = IN_TEMP[i+1];
                ValidIn = 1;
            end
        end
    endtask

    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0, tb_Digital_Filter_Parallel);
        $fsdbDumpMDA;
    end

    initial begin
        output_file = $fopen("../RTL/src/output.dat", "w");
        wait(ValidOut) begin
            for(j=0; j<`X_NUM_P; j=j+1) begin
                @(negedge clk);
                $fdisplay(output_file, "%0d", FilterOut0);
                $fdisplay(output_file, "%0d", FilterOut1);
                OUTPUT_CNT0 = j*2;
                OUTPUT_CNT1 = j*2 + 1;
            end
        end
        $fclose(output_file);
        $display("Ending of Output File written");
    end

endmodule