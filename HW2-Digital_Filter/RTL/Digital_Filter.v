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
`define X_WIDTH     16    // FilterIn Width
`define H_WIDTH     17
`define H_NUM       25
`define MUL_WIDTH   20
`define Y_WIDTH     21    // FilterOut Width


module Digital_Filter (
    input   wire                            clk,
    input   wire                            rst_n,
    input   wire    signed  [`X_WIDTH-1:0]  FilterIn,
    input   wire                            ValidIn,
    output  reg     signed  [`Y_WIDTH-1:0]  FilterOut,
    output  reg                             ValidOut
    );

    integer         i;
    localparam      IDLE    =   1'd0, 
                    OUT     =   1'd1;
    reg             state, next_state;
    //reg     [4:0]   cnt;

    reg     signed  [`H_WIDTH-1:0]   H   [0:`H_NUM-1];
    reg     signed  [`X_WIDTH-1:0]   X_D [0:`H_NUM-1];
    reg     signed  [`MUL_WIDTH-1:0] MUL [0:`H_NUM-1];
    reg     signed  [`X_WIDTH+`MUL_WIDTH-1:0] FULL_MUL; 
    
    initial $readmemb("../RTL/src/coeff.dat",H);

    always @(posedge clk or negedge rst_n) begin 
        if(!rst_n) begin // ALL Reset to Zero
            for(i=0; i<`H_NUM; i=i+1) X_D[i] <= 0;  
        end
        else if(ValidIn||state==OUT) begin // Shift Register
            X_D[0] <= FilterIn;
            for(i=0; i<`H_NUM-1; i=i+1) X_D[i+1] <= X_D[i];
        end
        else X_D[0] <= 0; // Reset to Zero
    end

    always @(*) begin
        for(i=0;i<`H_NUM; i=i+1) begin
            FULL_MUL = X_D[i] * H[i];
            MUL[i] = FULL_MUL[30:11];
            if(i==0) FilterOut = MUL[0];
            else FilterOut = MUL[i] + FilterOut;
        end
    end

   /* always @(posedge clk or negedge rst_n) begin
        if(!rst_n) cnt <= 0;
        else if(state==OUT&&!ValidIn) cnt <= cnt + 5'd1;
        else cnt <= 0;
    end*/

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) state <= IDLE;
        else state <= next_state;
    end

    always @(*) begin
        case(state)
            IDLE : next_state = (ValidIn)? OUT : IDLE;
            OUT : next_state = (!ValidIn)? IDLE : OUT;
        endcase
    end

    always @(posedge clk) ValidOut <= (next_state==OUT||state==OUT);
    
endmodule
