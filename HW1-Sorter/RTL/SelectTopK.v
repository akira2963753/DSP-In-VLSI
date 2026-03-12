/******************************************************************************
* Copyright (C) 2026 Marco
*
* File Name:    SelectTopK.v
* Project:      [HW1] 2026 Spring DSP In VLSI @NTU <ICDA5003>
* Module:       SelectTopK
* Author:       Marco <harry2963753@gmail.com>
* Student ID:   M11407439
* Tool:         Vivado 2025.1
* 
******************************************************************************/

module SelectTopK(
    input clk,
    input rst_n,
    input Blk_In,
    input signed [8:0] in0, in1, in2, in3, in4, in5, in6, in7,
    output reg signed [8:0] SortOut,
    output reg [1:0] OutRank);

    localparam IDLE = 2'd0, LOAD = 2'd1;
    reg state, next_state;

    integer i,j;

    wire signed [8:0] Sort8_out [0:3];
    reg  signed [8:0] Reg8_PingBuf [0:3][0:3];
    reg  signed [8:0] Reg8_PongBuf [0:3][0:3];

    reg signed [8:0] Group_out [0:3];
    reg signed [8:0] Winner_out [0:1];
    reg [1:0] Winner_Group [0:1];
    reg [1:0] Final_Winner_Group;

    reg [1:0] Reg_cnt;
    reg [2:0] Pointer [0:3];
    reg cmp_pending;
    reg Blk_In_Reg0, Blk_In_Reg1;

    Sort8 BitonicSorter(
        .in0(in0), 
        .in1(in1), 
        .in2(in2), 
        .in3(in3),
        .in4(in4), 
        .in5(in5), 
        .in6(in6), 
        .in7(in7),
        .clk(clk),
        .rst_n(rst_n),
        .out0(Sort8_out[0]),
        .out1(Sort8_out[1]),
        .out2(Sort8_out[2]),
        .out3(Sort8_out[3]),
        .out4(),
        .out5(),
        .out6(),
        .out7());
    

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            Blk_In_Reg0 <= 0;
            Blk_In_Reg1 <= 0;
        end
        else begin
            Blk_In_Reg0 <= Blk_In;
            Blk_In_Reg1 <= Blk_In_Reg0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) state <= IDLE;
        else state <= next_state;
    end

    always @(*) begin
        case(state)
            IDLE: next_state = (Blk_In_Reg1)? LOAD : IDLE;
            LOAD: next_state = (Reg_cnt == 2'd3)? IDLE : LOAD;
        endcase
    end

    always @(posedge clk) begin
        if(next_state==LOAD||state==LOAD) Reg_cnt <= Reg_cnt + 1;
        else Reg_cnt <= 0;
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) for(i=0; i<4; i=i+1) for(j=0; j<4; j=j+1) Reg8_PingBuf[i][j] <= 0;
        else if(next_state==LOAD||state==LOAD) begin
            for(i=0; i<4; i=i+1) if(Reg_cnt!=2'd3) Reg8_PingBuf[Reg_cnt][i] <= Sort8_out[i];
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) for(i=0; i<4; i=i+1) for(j=0; j<8; j=j+1) Reg8_PongBuf[i][j] <= 0;
        else if(state==LOAD && Reg_cnt == 2'd3) begin
            for(i=0; i<3; i=i+1) for(j=0; j<4; j=j+1) Reg8_PongBuf[i][j] <= Reg8_PingBuf[i][j];
            for(j=0; j<4; j=j+1) Reg8_PongBuf[3][j] <= Sort8_out[j];
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) for(i=0; i<4; i=i+1) Pointer[i] <= 0;
        else if(state==LOAD && Reg_cnt == 2'd3) for(i=0; i<4; i=i+1) Pointer[i] <= 0;
        else if(cmp_pending) Pointer[Final_Winner_Group] <= Pointer[Final_Winner_Group] + 1;
    end
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) cmp_pending <= 0;
        else if(state==LOAD && Reg_cnt == 2'd3) cmp_pending <= 1;
        else if(OutRank==2'd3) cmp_pending <= 0;
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) OutRank <= 0;
        else if(cmp_pending) OutRank <= OutRank + 1;
        else OutRank <= 0;
    end

    always @(*) begin
        if(cmp_pending) begin
            Group_out[0] = Reg8_PongBuf[0][Pointer[0]];
            Group_out[1] = Reg8_PongBuf[1][Pointer[1]];
            Group_out[2] = Reg8_PongBuf[2][Pointer[2]];
            Group_out[3] = Reg8_PongBuf[3][Pointer[3]];

            // Comparator 1 
            if(Group_out[0] > Group_out[1]) begin
                Winner_Group[0] = 2'd0;
                Winner_out[0] = Group_out[0];
            end
            else begin
                Winner_Group[0] = 2'd1;
                Winner_out[0] = Group_out[1];
            end

            // Comparator 2
            if(Group_out[2] > Group_out[3]) begin
                Winner_Group[1] = 2'd2;
                Winner_out[1] = Group_out[2];
            end
            else begin
                Winner_Group[1] = 2'd3;
                Winner_out[1] = Group_out[3];
            end

            // Comparator 3
            if(Winner_out[0] > Winner_out[1]) begin
                Final_Winner_Group = Winner_Group[0];
                SortOut = Winner_out[0];
            end
            else begin
                Final_Winner_Group = Winner_Group[1];
                SortOut = Winner_out[1];
            end
        end
        else begin
            Winner_Group[0] = 0;
            Winner_Group[1] = 0;
            Winner_out[0] = 0;
            Winner_out[1] = 0;
            Final_Winner_Group = 0;
            SortOut = 0;
        end
    end


endmodule
