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

`define X_WIDTH     16    // FilterIn Width (Q3.13)
`define H_WIDTH     17    // Coefficient Width (Q2.15) -> Q5.28
`define H_NUM       25    
`define MUL_WIDTH   20    // Mul Result Width (Q3.17)
`define Y_WIDTH     21    // FilterOut Width (Q4.17)
`define PIPE_STAGE  4

module Digital_Filter_Parallel (
    input   wire                            clk,
    input   wire                            rst_n,
    input   wire    signed  [`X_WIDTH-1:0]  FilterIn0,
    input   wire    signed  [`X_WIDTH-1:0]  FilterIn1,
    input   wire                            ValidIn,
    output  reg     signed  [`Y_WIDTH-1:0]  FilterOut0,
    output  reg     signed  [`Y_WIDTH-1:0]  FilterOut1,
    output  wire                            ValidOut);


    integer i;
    genvar n;
    localparam      IDLE    =   1'd0, 
                    OUT     =   1'd1;
    reg             state, next_state;
    reg     [2:0]   cnt;

    wire    signed  [`H_WIDTH-1:0]   H   [0:`H_NUM-1];
    reg     signed  [`X_WIDTH-1:0]   X_D [0:`H_NUM + 2*`PIPE_STAGE];
    reg     signed  [`MUL_WIDTH-1:0] MUL0 [0:`H_NUM-1];
    reg     signed  [`X_WIDTH+`H_WIDTH:0] FULL_MUL0 [0:`H_NUM-1]; // Q6.28

    reg     signed  [`MUL_WIDTH-1:0] MUL1 [0:`H_NUM-1];
    reg     signed  [`X_WIDTH+`H_WIDTH:0] FULL_MUL1 [0:`H_NUM-1]; // Q6.28


    reg     signed  [`Y_WIDTH-1:0] Y_REG_IN0  [0:`PIPE_STAGE-1];
    wire    signed  [`Y_WIDTH-1:0] Y_REG_OUT0 [0:`PIPE_STAGE-1];
    reg     signed  [`Y_WIDTH-1:0] Y_REG_IN1  [0:`PIPE_STAGE-1];
    wire    signed  [`Y_WIDTH-1:0] Y_REG_OUT1 [0:`PIPE_STAGE-1];

    // Five Stage Pipelined Stage
    reg     [`PIPE_STAGE-1:0] ValidOut_REG;

    generate
        for(n=0; n<`PIPE_STAGE; n=n+1) begin : PIPE_STAGE0
            Pipelined_Stage PIPE_Inst0(
                .clk(clk),
                .rst_n(rst_n),
                .Y_IN(Y_REG_IN0[n]),
                .Y_OUT(Y_REG_OUT0[n]));
        end
        for(n=0; n<`PIPE_STAGE; n=n+1) begin : PIPE_STAGE1
            Pipelined_Stage PIPE_Inst1(
                .clk(clk),
                .rst_n(rst_n),
                .Y_IN(Y_REG_IN1[n]),
                .Y_OUT(Y_REG_OUT1[n]));
        end
    endgenerate


    always @(posedge clk or negedge rst_n) begin 
        if(!rst_n) for(i=0; i<=(`H_NUM+2*`PIPE_STAGE); i=i+1) X_D[i] <= 0;
        else if(ValidIn||state==OUT) begin
            X_D[0] <= FilterIn1;
            X_D[1] <= FilterIn0;
            // Shift Register
            for(i=0; i<(`H_NUM + 2*`PIPE_STAGE)-1; i=i+1) X_D[i+2] <= X_D[i];
        end
        else begin 
            X_D[0] <= 0; 
            X_D[1] <= 0;
        end
    end

    always @(*) begin
        for(i=0; i<5; i=i+1) begin
            FULL_MUL0[i] = X_D[i+1] * H[i];
            FULL_MUL1[i] = X_D[i]   * H[i];
            MUL0[i] = FULL_MUL0[i][`X_WIDTH+`H_WIDTH-3 -: `MUL_WIDTH]; 
            MUL1[i] = FULL_MUL1[i][`X_WIDTH+`H_WIDTH-3 -: `MUL_WIDTH];
            if(i==0) begin 
                Y_REG_IN0[0] = {MUL0[0][`MUL_WIDTH-1],MUL0[0]};
                Y_REG_IN1[0] = {MUL1[0][`MUL_WIDTH-1],MUL1[0]};
            end
            else begin
                Y_REG_IN0[0] = {MUL0[i][`MUL_WIDTH-1],MUL0[i]} + Y_REG_IN0[0];
                Y_REG_IN1[0] = {MUL1[i][`MUL_WIDTH-1],MUL1[i]} + Y_REG_IN1[0];
            end
        end
        for(i=5; i<10; i=i+1) begin
            FULL_MUL0[i] = X_D[i+3] * H[i];
            FULL_MUL1[i] = X_D[i+2] * H[i];
            MUL0[i] = FULL_MUL0[i][`X_WIDTH+`H_WIDTH-3 -: `MUL_WIDTH]; 
            MUL1[i] = FULL_MUL1[i][`X_WIDTH+`H_WIDTH-3 -: `MUL_WIDTH];   
            if(i==5) begin 
                Y_REG_IN0[1] = {MUL0[5][`MUL_WIDTH-1],MUL0[5]} + Y_REG_OUT0[0];
                Y_REG_IN1[1] = {MUL1[5][`MUL_WIDTH-1],MUL1[5]} + Y_REG_OUT1[0];
            end
            else begin
                Y_REG_IN0[1] = {MUL0[i][`MUL_WIDTH-1],MUL0[i]} + Y_REG_IN0[1];
                Y_REG_IN1[1] = {MUL1[i][`MUL_WIDTH-1],MUL1[i]} + Y_REG_IN1[1];
            end         
        end
        for(i=10; i<15; i=i+1) begin
            FULL_MUL0[i] = X_D[i+5] * H[i];
            FULL_MUL1[i] = X_D[i+4] * H[i];
            MUL0[i] = FULL_MUL0[i][`X_WIDTH+`H_WIDTH-3 -: `MUL_WIDTH]; 
            MUL1[i] = FULL_MUL1[i][`X_WIDTH+`H_WIDTH-3 -: `MUL_WIDTH];   
            if(i==10) begin 
                Y_REG_IN0[2] = {MUL0[10][`MUL_WIDTH-1],MUL0[10]} + Y_REG_OUT0[1];
                Y_REG_IN1[2] = {MUL1[10][`MUL_WIDTH-1],MUL1[10]} + Y_REG_OUT1[1];
            end
            else begin
                Y_REG_IN0[2] = {MUL0[i][`MUL_WIDTH-1],MUL0[i]} + Y_REG_IN0[2];
                Y_REG_IN1[2] = {MUL1[i][`MUL_WIDTH-1],MUL1[i]} + Y_REG_IN1[2];
            end         
        end
        for(i=15; i<20; i=i+1) begin
            FULL_MUL0[i] = X_D[i+7] * H[i];
            FULL_MUL1[i] = X_D[i+6] * H[i];
            MUL0[i] = FULL_MUL0[i][`X_WIDTH+`H_WIDTH-3 -: `MUL_WIDTH]; 
            MUL1[i] = FULL_MUL1[i][`X_WIDTH+`H_WIDTH-3 -: `MUL_WIDTH];   
            if(i==15) begin 
                Y_REG_IN0[3] = {MUL0[15][`MUL_WIDTH-1],MUL0[15]} + Y_REG_OUT0[2];
                Y_REG_IN1[3] = {MUL1[15][`MUL_WIDTH-1],MUL1[15]} + Y_REG_OUT1[2];
            end
            else begin
                Y_REG_IN0[3] = {MUL0[i][`MUL_WIDTH-1],MUL0[i]} + Y_REG_IN0[3];
                Y_REG_IN1[3] = {MUL1[i][`MUL_WIDTH-1],MUL1[i]} + Y_REG_IN1[3];
            end         
        end
        for(i=20; i<25; i=i+1) begin
            FULL_MUL0[i] = X_D[i+9] * H[i];
            FULL_MUL1[i] = X_D[i+8] * H[i];
            MUL0[i] = FULL_MUL0[i][`X_WIDTH+`H_WIDTH-3 -: `MUL_WIDTH]; 
            MUL1[i] = FULL_MUL1[i][`X_WIDTH+`H_WIDTH-3 -: `MUL_WIDTH];   
            if(i==20) begin 
                FilterOut0 = {MUL0[20][`MUL_WIDTH-1],MUL0[20]} + Y_REG_OUT0[3];
                FilterOut1 = {MUL1[20][`MUL_WIDTH-1],MUL1[20]} + Y_REG_OUT1[3];
            end
            else begin
                FilterOut0 = {MUL0[i][`MUL_WIDTH-1],MUL0[i]} + FilterOut0;
                FilterOut1 = {MUL1[i][`MUL_WIDTH-1],MUL1[i]} + FilterOut1;
            end         
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) cnt <= 0;
        else if(state==OUT && !ValidIn) cnt <= cnt + 1;
        else cnt <= 0; 
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) state <= IDLE;
        else state <= next_state;
    end

    always @(*) begin
        case(state)
            IDLE : next_state = (ValidIn)? OUT : IDLE;
            OUT : next_state = (cnt==3'd4)? IDLE : OUT;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) ValidOut_REG <= 0;
        else begin
            ValidOut_REG[0] <= (state==OUT);
            for(i=0; i<`PIPE_STAGE-1; i=i+1) ValidOut_REG[i+1] <= ValidOut_REG[i];
        end
    end

    assign ValidOut = ValidOut_REG[`PIPE_STAGE-1] && (state==OUT);


	assign H[0] = 25'b0000000011111111111111111;
	assign H[1] = 25'b0000000011111010011100011;
	assign H[2] = 25'b0000000011110101011010100;
	assign H[3] = 25'b0000000011110010011010110;
	assign H[4] = 25'b0000000011110010110001001;
	assign H[5] = 25'b0000000011110111010001001;
	assign H[6] = 25'b0000000000000000000000000;
	assign H[7] = 25'b0000000000001100001110010;
	assign H[8] = 25'b0000000000011010011101101;
	assign H[9] = 25'b0000000000101000101111100;
	assign H[10] = 25'b0000000000110100111011010;
	assign H[11] = 25'b0000000000111101000111011;
	assign H[12] = 25'b0000000001000000000000000;
	assign H[13] = 25'b0000000000111101000111011;
	assign H[14] = 25'b0000000000110100111011010;
	assign H[15] = 25'b0000000000101000101111100;
	assign H[16] = 25'b0000000000011010011101101;
	assign H[17] = 25'b0000000000001100001110010;
	assign H[18] = 25'b0000000000000000000000000;
	assign H[19] = 25'b0000000011110111010001001;
	assign H[20] = 25'b0000000011110010110001001;
	assign H[21] = 25'b0000000011110010011010110;
	assign H[22] = 25'b0000000011110101011010100;
	assign H[23] = 25'b0000000011111010011100011;
	assign H[24] = 25'b0000000011111111111111111;    
    
endmodule


module Pipelined_Stage (
    input   wire    clk,
    input   wire    rst_n,
    input   wire    signed  [`Y_WIDTH-1:0]  Y_IN,
    output  reg     signed  [`Y_WIDTH-1:0]  Y_OUT);

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) Y_OUT <= 0;
        else Y_OUT <= Y_IN;
    end
    
endmodule
