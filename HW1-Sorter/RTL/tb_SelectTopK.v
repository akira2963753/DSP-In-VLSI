
/******************************************************************************
* Copyright (C) 2026 Marco 
*
* File Name:    tb_SelectTopK.v
* Project:      [HW1] 2026 Spring DSP In VLSI @NTU <ICDA5003>
* Module:       tb_SelectTopK
* Author:       Marco <harry2963753@gmail.com>
* Student ID:   M11407439
* Tool:         Vivado 2025.1
* 
******************************************************************************/
`define TEST_CASE 1

module tb_SelectTopK();

    reg clk, rst_n, Blk_In;
    reg signed [8:0] in[0:7];
    wire signed [8:0] SortOut;
    wire [1:0] OutRank;

    integer i,j,file;

    SelectTopK DUT(
        .clk(clk),
        .rst_n(rst_n),
        .Blk_In(Blk_In),
        .in0(in[0]),
        .in1(in[1]),
        .in2(in[2]),
        .in3(in[3]),
        .in4(in[4]),
        .in5(in[5]),
        .in6(in[6]),
        .in7(in[7]),
        .SortOut(SortOut),
        .OutRank(OutRank));

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 1;
        Blk_In = 0;
        #20;
        @(negedge clk) rst_n = 0;
        @(negedge clk) rst_n = 1;
        file = $fopen("D:/DSP-In-VLSI/HW1-Sorter/Verification/input.dat", "w");
        if(file == 0) begin
            $display("ERROR: Cannot open file!");
            $finish;
        end
        for(j=0; j<`TEST_CASE; j=j+1) Input_Data();
        @(negedge clk) for(i=0; i<8; i=i+1) in[i] = 0; 
        $fclose(file);
        #100 $finish;
    end

    task Input_Data;
        begin
            @(negedge clk) Blk_In = 1;
            Random_Input_Gen();
            @(negedge clk) Blk_In = 0;
            Random_Input_Gen();
            @(negedge clk);
            Random_Input_Gen();
            @(negedge clk);
            Random_Input_Gen();
        end
    endtask

    task Random_Input_Gen;
        begin
            for(i=0; i<8; i=i+1) begin 
                in[i] = ($random & 9'h1FF) - 256;
                $fdisplay(file, "%0d", $signed(in[i]));
            end
        end
    endtask

endmodule