/******************************************************************************
* Copyright (C) 2026 Marco
*
* File Name:    SDF_FFT.sv
* Project:      [HW5] 2026 Spring DSP In VLSI @NTU <ICDA5003>
* Module:       SDF_FFT
* Author:       Marco <harry2963753@gmail.com>
* Student ID:   M11407439
* Tool:         VCS & Verdi
* Comment Opt:  Claude Code
*
******************************************************************************/
`include "define.vh"
`timescale 1ns/1ps

module SDF_FFT(
    input   clk,
    input   rst_n,
    input   InValid,
    input   signed [`DATA_WIDTH-1:0]   FFTInRe,
    input   signed [`DATA_WIDTH-1:0]   FFTInIm,
    output  logic signed [`DATA_WIDTH-1:0]   SDFOutRe,
    output  logic signed [`DATA_WIDTH-1:0]   SDFOutIm,
    output  logic   OutValid);

    // Counter and Control Signals
    logic [`CNT_WIDTH-1:0] cnt [0:`STAGE_SIZE-1];   // main Counter
    logic BF_en [0:`STAGE_SIZE-1];                  // butterfly Enable
    logic [34:0] valid_pipe;                        // pipeline for InValid to OutValid

    // Flush counter to avoid stopping when InValid = 0
    logic [`CNT_WIDTH:0] flush_cnt; // calculate when output done
    logic InValid_d;                // catch the negedge of InValid
    logic InterValid;               // intermediate valid signal
    logic InValid_r;                // Sample InValid at posedge of clock

    // ROM for twiddle factors
    logic signed [`TWIDDLE_WIDTH-1:0] ROM32 [0:7];
    logic signed [`TWIDDLE_WIDTH-1:0] ROM16 [0:3];
    logic signed [`TWIDDLE_WIDTH-1:0] ROM8 [0:1];

    // Stage Outputs
    logic signed [`DATA_WIDTH-1:0] SOut_Re[0:`STAGE_SIZE-1];
    logic signed [`DATA_WIDTH-1:0] SOut_Im[0:`STAGE_SIZE-1];
    
    // Stage Pipelined Registers
    logic signed [`DATA_WIDTH-1:0] In_Re[0:`STAGE_SIZE-1];
    logic signed [`DATA_WIDTH-1:0] In_Im[0:`STAGE_SIZE-1];

    // Twiddle factors for each stage
    logic signed [`TWIDDLE_WIDTH-1:0] TF_Re[0:`STAGE_SIZE-2];
    logic signed [`TWIDDLE_WIDTH-1:0] TF_Im[0:`STAGE_SIZE-2];

    FFT_PE #(
        .STAGE(16),
        .IDX_WIDTH(4)
    ) STAGE01(
        .clk(clk),
        .rst_n(rst_n),
        .En(BF_en[0]),
        .Idx(cnt[0][3:0]),
        .In_Re(In_Re[0]),
        .In_Im(In_Im[0]),
        .TF_Re(TF_Re[0]),
        .TF_Im(TF_Im[0]),
        .SOut_Re(SOut_Re[0]),
        .SOut_Im(SOut_Im[0]));
    
    FFT_PE #(
        .STAGE(8),
        .IDX_WIDTH(3)
    ) STAGE02(
        .clk(clk),
        .rst_n(rst_n),
        .En(BF_en[1]),
        .Idx(cnt[1][2:0]),
        .In_Re(In_Re[1]),
        .In_Im(In_Im[1]),
        .TF_Re(TF_Re[1]),
        .TF_Im(TF_Im[1]),
        .SOut_Re(SOut_Re[1]),
        .SOut_Im(SOut_Im[1]));
    
    FFT_PE #(
        .STAGE(4),
        .IDX_WIDTH(2)
    ) STAGE03(
        .clk(clk),
        .rst_n(rst_n),
        .En(BF_en[2]),
        .Idx(cnt[2][1:0]),
        .In_Re(In_Re[2]),
        .In_Im(In_Im[2]),
        .TF_Re(TF_Re[2]),
        .TF_Im(TF_Im[2]),
        .SOut_Re(SOut_Re[2]),
        .SOut_Im(SOut_Im[2]));
    
    FFT_PE #(
        .STAGE(2),
        .IDX_WIDTH(1)
    ) STAGE04(
        .clk(clk),
        .rst_n(rst_n),
        .En(BF_en[3]),
        .Idx(cnt[3][0]),
        .In_Re(In_Re[3]),
        .In_Im(In_Im[3]),
        .TF_Re(TF_Re[3]),
        .TF_Im(TF_Im[3]),
        .SOut_Re(SOut_Re[3]),
        .SOut_Im(SOut_Im[3]));

    FFT_FINAL_PE STAGE05(
        .clk(clk),
        .rst_n(rst_n),
        .En(BF_en[4]),
        .In_Re(In_Re[4]),
        .In_Im(In_Im[4]),
        .SOut_Re(SOut_Re[4]),
        .SOut_Im(SOut_Im[4]));

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            InValid_r <= 0;
            flush_cnt <= 0;
            InValid_d <= 0;
        end 
        else begin
            InValid_r <= InValid; // Sample Input Valid
            InValid_d <= InValid_r; // Detect Negative-Edge of InValid
            if (!InValid_r && InValid_d) flush_cnt <= 35; // 30(cal) + 1(Input Sample) + 4(Pipe) = 35 Cycles
            else if (flush_cnt!=0 && !InValid_r) flush_cnt <= flush_cnt - 1;
            else flush_cnt <= 0;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin : COUNTER_BLOCK
        if(!rst_n) for(int i = 0; i < `STAGE_SIZE; i++) cnt[i] <= 0;
        else if(InterValid) begin
            cnt[0] <= cnt[0] + 1;
            for(int i = 1; i < `STAGE_SIZE; i++) cnt[i] <= cnt[i-1];
        end
        else for(int i = 0; i < `STAGE_SIZE; i++) cnt[i] <= 0;
    end

    always_comb begin : CONTROL_BLOCK
        // Flush counter: auto-flush pipeline 31 cycles after InValid falls
        InterValid = InValid_r || InValid_d || (flush_cnt != 0);
        for(int i = 0; i < `STAGE_SIZE; i++) BF_en[i] = InterValid && cnt[i][4-i];
    end

    always_ff @(posedge clk or negedge rst_n) begin : PIPELINED_STAGE
        if(!rst_n) begin
            for(int i = 0; i < `STAGE_SIZE; i++) begin
                In_Re[i] <= 0;
                In_Im[i] <= 0;
            end
        end
        else begin
            for(int i = 0; i < `STAGE_SIZE; i++) begin
                if(i==0) begin // Sample Input 
                    In_Re[0] <= FFTInRe;
                    In_Im[0] <= FFTInIm;
                end
                else begin
                    In_Re[i] <= SOut_Re[i-1];
                    In_Im[i] <= SOut_Im[i-1];
                end
            end
        end
    end

    always_comb begin : TF_LUT
        if(cnt[0][3:0]==0) begin
            TF_Re[0] = 11'sd512;
            TF_Im[0] = 0;
        end
        else if(cnt[0][3:0]==8) begin
            TF_Re[0] = 0;
            TF_Im[0] = -11'sd512;            
        end
        else if(cnt[0][3]) begin
            TF_Re[0] = -ROM32[8-cnt[0][2:0]];
            TF_Im[0] = -ROM32[cnt[0][2:0]];
        end
        else begin
            TF_Re[0] = ROM32[cnt[0][2:0]];
            TF_Im[0] = -ROM32[8-cnt[0][2:0]];
        end
        if(cnt[1][2:0]==0) begin
            TF_Re[1] = 11'sd512;
            TF_Im[1] = 0;
        end
        else if(cnt[1][2:0]==4) begin
            TF_Re[1] = 0;
            TF_Im[1] = -11'sd512;
        end
        else if(cnt[1][2]) begin
            TF_Re[1] = -ROM16[4-cnt[1][1:0]];
            TF_Im[1] = -ROM16[cnt[1][1:0]];
        end
        else begin
            TF_Re[1] = ROM16[cnt[1][1:0]];
            TF_Im[1] = -ROM16[4-cnt[1][1:0]];
        end
        if(cnt[2][1:0]==0) begin
            TF_Re[2] = 11'sd512;
            TF_Im[2] = 0;
        end
        else if(cnt[2][1:0]==2) begin
            TF_Re[2] = 0;
            TF_Im[2] = -11'sd512;
        end
        else if(cnt[2][1]) begin
            TF_Re[2] = -ROM8[2-cnt[2][0]];
            TF_Im[2] = -ROM8[cnt[2][0]];
        end
        else begin
            TF_Re[2] = ROM8[cnt[2][0]];
            TF_Im[2] = -ROM8[2-cnt[2][0]];
        end
        if(cnt[3][0]) begin
            TF_Re[3] = 0;
            TF_Im[3] = -11'sd512;
        end
        else begin
            TF_Re[3] = 11'sd512;
            TF_Im[3] = 0;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin : OUTPUT_BLOCK
        if(!rst_n) begin
            SDFOutRe <= 0;
            SDFOutIm <= 0;
            OutValid <= 0;       
        end
        else begin
            SDFOutRe <= SOut_Re[4];
            SDFOutIm <= SOut_Im[4];
            OutValid <= valid_pipe[34]; // 30 + 4(Pipe) = 34 Cycles
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) valid_pipe <= 0;
        else valid_pipe <= {valid_pipe[33:0], InValid_r};
    end

    always_comb begin : ROM_LUT
        ROM32[0] = 11'sd512;    // Redundary Logic, removed by synthesis
        ROM32[1] = 11'sd502;
        ROM32[2] = 11'sd473;
        ROM32[3] = 11'sd425;
        ROM32[4] = 11'sd362;
        ROM32[5] = 11'sd284;
        ROM32[6] = 11'sd195;
        ROM32[7] = 11'sd99;
        ROM16[0] = 11'sd512;    // Redundary Logic, removed by synthesis
        ROM16[1] = 11'sd473;
        ROM16[2] = 11'sd362;
        ROM16[3] = 11'sd195;
        ROM8[0] = 11'sd512;     // Redundary Logic, removed by synthesis
        ROM8[1] = 11'sd362;
    end

endmodule


module FFT_PE #(
    parameter STAGE = 16,
    parameter IDX_WIDTH = $clog2(STAGE))(
    input   clk,
    input   rst_n,
    input   En,
    input   [IDX_WIDTH-1:0] Idx,
    input   signed [`DATA_WIDTH-1:0] In_Re,
    input   signed [`DATA_WIDTH-1:0] In_Im,
    input   signed [`TWIDDLE_WIDTH-1:0] TF_Re,
    input   signed [`TWIDDLE_WIDTH-1:0] TF_Im,
    output  logic signed [`DATA_WIDTH-1:0] SOut_Re,
    output  logic signed [`DATA_WIDTH-1:0] SOut_Im);

    logic signed [`DATA_WIDTH-1:0] DeBuf_Re [0:STAGE-1];
    logic signed [`DATA_WIDTH-1:0] DeBuf_Im [0:STAGE-1];
    logic signed [`DATA_WIDTH*2-1:0] Mul_Result;

    // Complex Multiplication : (a+jb)(c+jd) = (ac-bd) + j(ad+bc) 
    function automatic signed [`DATA_WIDTH*2-1:0] complex_mul;
        input signed [`DATA_WIDTH-1:0] a, b;
        input signed [`TWIDDLE_WIDTH-1:0] c, d;
        logic signed [`DATA_WIDTH+`TWIDDLE_WIDTH-1:0] ac;
        logic signed [`DATA_WIDTH+`TWIDDLE_WIDTH-1:0] bd;
        logic signed [`DATA_WIDTH+`TWIDDLE_WIDTH-1:0] ad;
        logic signed [`DATA_WIDTH+`TWIDDLE_WIDTH-1:0] bc;
        logic signed [`DATA_WIDTH+`TWIDDLE_WIDTH-1:0] ac_bd;
        logic signed [`DATA_WIDTH+`TWIDDLE_WIDTH-1:0] ad_bc;
        logic signed [`DATA_WIDTH-1:0] ReResult;
        logic signed [`DATA_WIDTH-1:0] ImResult;
        begin 
            ac = a * c;
            bd = b * d;
            ad = a * d;
            bc = b * c;
            ac_bd = ac - bd;
            ad_bc = ad + bc;

            // 1S 6I 9F x 1S 1I 9F = 1S 8I 18F truncated to 1S 6I 9F 
            ReResult = ac_bd[`DATA_WIDTH + 9 - 1 -: `DATA_WIDTH];
            ImResult = ad_bc[`DATA_WIDTH + 9 - 1 -: `DATA_WIDTH];
            complex_mul = {ReResult, ImResult};
        end
    endfunction
    
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin 
            for(int i=0; i<STAGE; i++) begin
                DeBuf_Re[i] <= 0;
                DeBuf_Im[i] <= 0;
            end
        end
        else if(En) begin
            // [ButterFly] Subtract and Save into Buffer
            DeBuf_Re[Idx] <= DeBuf_Re[Idx] - In_Re;
            DeBuf_Im[Idx] <= DeBuf_Im[Idx] - In_Im;
        end
        else begin
            // [ByPass] Save New Value into Buffer
            DeBuf_Re[Idx] <= In_Re;
            DeBuf_Im[Idx] <= In_Im;
        end
    end

    always_comb begin
        if(En) begin
            // [ButterFly] Add and transfer to next stage
            SOut_Re = In_Re + DeBuf_Re[Idx];
            SOut_Im = In_Im + DeBuf_Im[Idx];
            Mul_Result = 0;
        end
        else begin
            // [ByPass] Complex Multiplication
            Mul_Result = complex_mul(DeBuf_Re[Idx], DeBuf_Im[Idx], TF_Re, TF_Im);
            SOut_Re= Mul_Result[`DATA_WIDTH*2-1 -: `DATA_WIDTH];
            SOut_Im= Mul_Result[`DATA_WIDTH-1 -: `DATA_WIDTH];
        end
    end

endmodule


// Final Stage : No Complex Multiplication
module FFT_FINAL_PE (
    input   clk,
    input   rst_n,
    input   En,
    input   signed [`DATA_WIDTH-1:0] In_Re,
    input   signed [`DATA_WIDTH-1:0] In_Im,
    output  logic signed [`DATA_WIDTH-1:0] SOut_Re,
    output  logic signed [`DATA_WIDTH-1:0] SOut_Im);

    logic signed [`DATA_WIDTH-1:0] DeBuf_Re;
    logic signed [`DATA_WIDTH-1:0] DeBuf_Im;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin 
            DeBuf_Re <= 0;
            DeBuf_Im <= 0;
        end
        else if(En) begin
            // [ButterFly] Subtract and Save into Buffer
            DeBuf_Re <= DeBuf_Re - In_Re;
            DeBuf_Im <= DeBuf_Im - In_Im;
        end
        else begin
            // [ByPass] Save New Value into Buffer
            DeBuf_Re <= In_Re;
            DeBuf_Im <= In_Im;
        end
    end

    always_comb begin
        if(En) begin
            // [ButterFly] Add and transfer to next stage
            SOut_Re = In_Re + DeBuf_Re;
            SOut_Im = In_Im + DeBuf_Im;
        end
        else begin
            // [ByPass] Save New Value into Buffer
            SOut_Re = DeBuf_Re;
            SOut_Im = DeBuf_Im;
        end
    end

endmodule