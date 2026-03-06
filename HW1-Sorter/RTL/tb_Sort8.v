/******************************************************************************
* Copyright (C) 2026 Marco 
*
* File Name:    tb_Sort8.v
* Project:      [HW1] 2026 Spring DSP In VLSI @NTU <ICDA5003>
* Module:       tb_Sort8
* Author:       Marco <harry2963753@gmail.com>
* Student ID:   M11407439
* Tool:         Vivado 2025.1
* 
******************************************************************************/
`define TEST_CASE 100
module tb_Sort8();

    reg clk;
    reg rst_n;
    reg signed [8:0] In[0:7];
    wire signed [8:0] Out[0:7];

    Sort8 DUT(In[0], In[1], In[2], In[3], In[4], In[5], In[6], In[7],
              clk, rst_n,
              Out[0], Out[1], Out[2], Out[3], Out[4], Out[5], Out[6], Out[7]);

    integer i,j;

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 1;
        for(i=0; i<8; i=i+1) In[i] = 0;
        @(negedge clk) rst_n = 0;
        @(negedge clk) rst_n = 1;
        for(j=0; j<`TEST_CASE; j=j+1) begin
            Radnom_Input_Gen();
            Verify_Result();
        end
        #100 $display("Test Pass !!");
        $finish;
    end

    task Radnom_Input_Gen;
        begin
             @(negedge clk);
            for(i=0; i<8; i=i+1) begin
                In[i] = ($random & 9'h1FF) - 256;
            end        
        end
    endtask

    task Verify_Result;
        begin
            for(i=0; i<7; i=i+1) begin
                if(Out[i] < Out[i+1]) begin
                    $display("Test Fail !!");
                    #10 $finish;
                end 
            end
            #10;
        end
    endtask

endmodule