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
`define X_WIDTH     16    // FilterIn Width
`define Y_WIDTH     21    // FilterOut Width
`define X_NUM       144

`timescale 1ns/1ps
module tb_Digital_Filter();

    reg clk;
    reg rst_n;
    reg signed [`X_WIDTH-1:0] FilterIn;
    reg ValidIn;
    wire signed [`Y_WIDTH-1:0] FilterOut;
    wire ValidOut;
    reg [7:0] OUTPUT_CNT;

    integer i,j;
    integer output_file;
    Digital_Filter DUT(.*);

    reg signed [`X_WIDTH-1:0] IN_TEMP [0:`X_NUM-1];
    initial $readmemb("../RTL/src/input.dat",IN_TEMP);

    always #5 clk = ~clk;

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
        output_file = $fopen("../RTL/src/output.dat", "w");
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
