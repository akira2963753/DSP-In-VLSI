/******************************************************************************
* Copyright (C) 2026 Marco
*
* File Name:    Sort8.v
* Project:      [HW1] 2026 Spring DSP In VLSI @NTU <ICDA5003>
* Module:       Sort8
* Author:       Marco <harry2963753@gmail.com>
* Student ID:   M11407439
* Tool:         Vivado 2025.1
* 
******************************************************************************/

module Sort8 (
    input signed [8:0] in0, in1, in2, in3, in4, in5, in6, in7,
    input clk,
    input rst_n,
    output signed [8:0] out0, out1, out2, out3, out4, out5, out6, out7);


    integer i;

    wire signed [8:0] s1_out [0:7];
    wire signed [8:0] s2_out [0:7];
    reg  signed [8:0] s2_out_reg [0:7];
    wire signed [8:0] s3_out [0:7];
    wire signed [8:0] s4_out [0:7];
    reg  signed [8:0] s4_out_reg [0:7];
    wire signed [8:0] s5_out [0:7];

    // Bitonic Sorter for 8 elements

    // Pipeline registers for Stage 2 and Stage 4 outputs
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i=0; i<8; i=i+1) s2_out_reg[i] <= 0;
            for(i=0; i<8; i=i+1) s4_out_reg[i] <= 0;
        end
        else begin
            for(i=0; i<8; i=i+1) s2_out_reg[i] <= s2_out[i];
            for(i=0; i<8; i=i+1) s4_out_reg[i] <= s4_out[i];
        end
    end   

    // Stage 1
    CAS Stage1_0(in0, in1, 1, s1_out[0], s1_out[1]);
    CAS Stage1_1(in2, in3, 0, s1_out[2], s1_out[3]);
    CAS Stage1_2(in4, in5, 1, s1_out[4], s1_out[5]);
    CAS Stage1_3(in6, in7, 0, s1_out[6], s1_out[7]);

    // Stage 2
    CAS Stage2_0(s1_out[0], s1_out[2], 1, s2_out[0], s2_out[2]);
    CAS Stage2_1(s1_out[1], s1_out[3], 1, s2_out[1], s2_out[3]);
    CAS Stage2_2(s1_out[4], s1_out[6], 0, s2_out[4], s2_out[6]);
    CAS Stage2_3(s1_out[5], s1_out[7], 0, s2_out[5], s2_out[7]); 

    // Stage 3
    CAS Stage3_0(s2_out_reg[0], s2_out_reg[1], 1, s3_out[0], s3_out[1]);
    CAS Stage3_1(s2_out_reg[2], s2_out_reg[3], 1, s3_out[2], s3_out[3]);
    CAS Stage3_2(s2_out_reg[4], s2_out_reg[5], 0, s3_out[4], s3_out[5]);
    CAS Stage3_3(s2_out_reg[6], s2_out_reg[7], 0, s3_out[6], s3_out[7]);

    // Stage 4
    CAS Stage4_0(s3_out[0], s3_out[4], 1, s4_out[0], s4_out[4]);
    CAS Stage4_1(s3_out[1], s3_out[5], 1, s4_out[1], s4_out[5]);
    CAS Stage4_2(s3_out[2], s3_out[6], 1, s4_out[2], s4_out[6]);
    CAS Stage4_3(s3_out[3], s3_out[7], 1, s4_out[3], s4_out[7]);

    // Stage 5
    CAS Stage5_0(s4_out_reg[0], s4_out_reg[2], 1, s5_out[0], s5_out[2]);
    CAS Stage5_1(s4_out_reg[1], s4_out_reg[3], 1, s5_out[1], s5_out[3]);
    CAS Stage5_2(s4_out_reg[4], s4_out_reg[6], 1, s5_out[4], s5_out[6]);
    CAS Stage5_3(s4_out_reg[5], s4_out_reg[7], 1, s5_out[5], s5_out[7]);

    // Stage 6
    CAS Stage6_0(s5_out[0], s5_out[1], 1, out0, out1);
    CAS Stage6_1(s5_out[2], s5_out[3], 1, out2, out3);
    CAS Stage6_2(s5_out[4], s5_out[5], 1, out4, out5);
    CAS Stage6_3(s5_out[6], s5_out[7], 1, out6, out7);

endmodule

module CAS(
    input signed [8:0] in0, in1,
    input sel, // 0 : Ascending, 1 : Descending
    output reg signed [8:0] out0, out1);

    always @(*) begin
        if(in0 < in1) begin
            if(sel) begin
                out0 = in1;
                out1 = in0;
            end
            else begin
                out0 = in0;
                out1 = in1;
            end
        end
        else begin
            if(sel) begin
                out0 = in0;
                out1 = in1;
            end
            else begin
                out0 = in1;
                out1 = in0;
            end
        end
    end

endmodule