/******************************************************************************
* Copyright (C) 2026 Marco
*
* File Name:    Digital_Filter.v
* Project:      [HW2] 2026 Spring DSP In VLSI @NTU <ICDA5003>
* Module:       Digital_Filter
* Author:       Marco <harry2963753@gmail.com>
* Student ID:   M11407439
* Tool:         VCS & Verdi
*
******************************************************************************/
`timescale 1ns/1ps

`define X_WIDTH     16    // FilterIn Width (Q3.13)
`define H_WIDTH     17    // Coefficient Width (Q2.15) -> Q6.28
`define H_NUM       25
`define MUL_WIDTH   20    // Mul Result Width (Q3.17)
`define Y_WIDTH     21    // FilterOut Width (Q4.17)
`define PIPE_STAGE  4

module Digital_Filter (
    input   logic                           clk,
    input   logic                           rst_n,
    input   logic   signed  [`X_WIDTH-1:0]  FilterIn,
    input   logic                           ValidIn,
    output  logic   signed  [`Y_WIDTH-1:0]  FilterOut,
    output  logic                           ValidOut
    );

    int i;
    genvar  n;
    localparam      IDLE    =   1'd0,
                    OUT     =   1'd1;
    logic           state, next_state;
    logic   [2:0]   cnt;

    logic   signed  [`H_WIDTH-1:0]   H   [0:`H_NUM-1];
    logic   signed  [`X_WIDTH-1:0]   X_D [0:`H_NUM-1];
    logic   signed  [`MUL_WIDTH-1:0] MUL [0:`H_NUM-1];
    logic   signed  [`X_WIDTH+`H_WIDTH:0] FULL_MUL [0:`H_NUM-1]; // Q6.28

    // Five Stage Pipelined Stage
    logic   signed  [`X_WIDTH-1:0] X_REG_OUT [0:`PIPE_STAGE-1];
    logic   signed  [`Y_WIDTH-1:0] Y_REG_IN  [0:`PIPE_STAGE-1];
    logic   signed  [`Y_WIDTH-1:0] Y_REG_OUT [0:`PIPE_STAGE-1];
    logic   [`PIPE_STAGE-1:0] ValidOut_REG;

    generate
        for(n=0; n<`PIPE_STAGE; n=n+1) begin : Stage
            Pipelined_Stage Pipe_Inst(
                .clk(clk),
                .rst_n(rst_n),
                .X_IN(X_D[(n+1)*5-1]),
                .X_OUT(X_REG_OUT[n]),
                .Y_IN(Y_REG_IN[n]),
                .Y_OUT(Y_REG_OUT[n]));
        end
    endgenerate

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) for(i=0; i<`H_NUM; i=i+1) X_D[i] <= 0;
        else if(ValidIn||state==OUT) begin // Shift Register
            // Five Stage Pipeline
            X_D[0] <= FilterIn;
            X_D[5] <= X_REG_OUT[0];
            X_D[10] <= X_REG_OUT[1];
            X_D[15] <= X_REG_OUT[2];
            X_D[20] <= X_REG_OUT[3];
            for(i=0; i<4; i=i+1) X_D[i+1] <= X_D[i];
            for(i=5; i<9; i=i+1) X_D[i+1] <= X_D[i];
            for(i=10; i<14; i=i+1) X_D[i+1] <= X_D[i];
            for(i=15; i<19; i=i+1) X_D[i+1] <= X_D[i];
            for(i=20; i<24; i=i+1) X_D[i+1] <= X_D[i];
        end
        else X_D[0] <= 0; // Reset to Zero
    end

    always_comb begin
        for(i=0;i<`H_NUM; i=i+1) begin
            FULL_MUL[i] = X_D[i] * H[i];
            MUL[i] = FULL_MUL[i][`X_WIDTH+`H_WIDTH-3 -: `MUL_WIDTH];
        end
    end

    always_comb begin
        for(i=0; i<5; i=i+1) begin
            if(i==0) Y_REG_IN[0] = {MUL[0][`MUL_WIDTH-1],MUL[0]};
            else Y_REG_IN[0] = {MUL[i][`MUL_WIDTH-1],MUL[i]} + Y_REG_IN[0];
        end
        for(i=5; i<10; i=i+1) begin
            if(i==5) Y_REG_IN[1] = Y_REG_OUT[0] + {MUL[5][`MUL_WIDTH-1],MUL[5]};
            else Y_REG_IN[1] = {MUL[i][`MUL_WIDTH-1],MUL[i]} + Y_REG_IN[1];
        end
        for(i=10; i<15; i=i+1) begin
            if(i==10) Y_REG_IN[2] = Y_REG_OUT[1] + {MUL[10][`MUL_WIDTH-1],MUL[10]};
            else Y_REG_IN[2] = {MUL[i][`MUL_WIDTH-1],MUL[i]} + Y_REG_IN[2];
        end
        for(i=15; i<20; i=i+1) begin
            if(i==15) Y_REG_IN[3] = Y_REG_OUT[2] + {MUL[15][`MUL_WIDTH-1],MUL[15]};
            else Y_REG_IN[3] = {MUL[i][`MUL_WIDTH-1],MUL[i]} + Y_REG_IN[3];
        end
        for(i=20; i<25; i=i+1) begin
            if(i==20) FilterOut = Y_REG_OUT[3] + {MUL[20][`MUL_WIDTH-1],MUL[20]};
            else FilterOut = {MUL[i][`MUL_WIDTH-1],MUL[i]} + FilterOut;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) cnt <= 0;
        else if(state==OUT && !ValidIn) cnt <= cnt + 1;
        else cnt <= 0;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) state <= IDLE;
        else state <= next_state;
    end

    always_comb begin
        case(state)
            IDLE : next_state = (ValidIn)? OUT : IDLE;
            OUT  : next_state = (cnt==3'd4)? IDLE : OUT;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
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
    input   logic   clk,
    input   logic   rst_n,
    input   logic   signed  [`X_WIDTH-1:0]  X_IN,
    input   logic   signed  [`Y_WIDTH-1:0]  Y_IN,
    output  logic   signed  [`X_WIDTH-1:0]  X_OUT,
    output  logic   signed  [`Y_WIDTH-1:0]  Y_OUT);

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            X_OUT <= 0;
            Y_OUT <= 0;
        end
        else begin
            X_OUT <= X_IN;
            Y_OUT <= Y_IN;
        end
    end

endmodule
