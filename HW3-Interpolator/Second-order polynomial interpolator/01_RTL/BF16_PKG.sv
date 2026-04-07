/******************************************************************************
* Copyright (C) 2026 Marco
*
* File Name:    BF16_PKG.sv
* Project:      [HW3] 2026 Spring DSP In VLSI @NTU <ICDA5003>
* Module:       BF16_PKG
* Author:       Marco <harry2963753@gmail.com>
* Student ID:   M11407439
* Tool:         VCS & Verdi
* 
******************************************************************************/
`include "define.vh"
`timescale 1ns/1ps

// Function 記得要使用 Autoamatic，才能被正確合成
package BF16_PKG;
    // Leading One Detector: 回傳需左移幾位才能讓 implicit 1 回到 bit7
    function automatic [2:0] LOD;
        input [`MIN_WIDTH:0] val; // 8-bit: Result_add[MIN_WIDTH:0]
        begin
            casez(val)
                8'b1???????: LOD = 3'd0;
                8'b01??????: LOD = 3'd1;
                8'b001?????: LOD = 3'd2;
                8'b0001????: LOD = 3'd3;
                8'b00001???: LOD = 3'd4;
                8'b000001??: LOD = 3'd5;
                8'b0000001?: LOD = 3'd6;
                default:     LOD = 3'd7;
            endcase
        end
    endfunction

    // BF16 x 0.5 Function (x0.5 很常用到，而且可以不用乘法器，可以寫一個專用 Function)
    function automatic [`IO_WIDTH-1:0] BF16_HALF;
        input [`IO_WIDTH-1:0] A;
        logic A_sign;
        logic [`EXP_WIDTH-1:0] A_exp;
        logic [`MIN_WIDTH-1:0] A_min;

        begin
            BF16_HALF = 16'h0000; // Default output

            // 提取符號、指數和尾數
            {A_sign, A_exp, A_min} = A;
            if(A_exp <= `EXP_WIDTH'd1) BF16_HALF = 16'h0000; // Underflow
            else BF16_HALF = {A_sign, A_exp - `EXP_WIDTH'd1, A_min}; // 指數減1

            // 上面這裡要注意一個陷阱，使用 {} 來組合的時候，如果直接寫 A_exp - 1 
            // 會被當成 32-bit 的減法，導致結果不正確
        end
    endfunction

    // BF16 Addition Function
    function automatic [`IO_WIDTH-1:0] BF16_ADD;
        input [`IO_WIDTH-1:0] A, B;

        logic A_sign, B_sign;
        logic [`EXP_WIDTH-1:0] A_exp, B_exp;
        logic [`MIN_WIDTH-1:0] A_min, B_min;
        logic [`MIN_WIDTH+1:0] Result_add; // 9 bits for addition result
        logic [`MIN_WIDTH-1:0] Result_min;
        logic [`EXP_WIDTH-1:0] Result_exp;
        logic Result_sign;
        logic [`EXP_WIDTH-1:0] Exp_diff;
        logic [`MIN_WIDTH:0] A_min_aligned, B_min_aligned;
        logic [2:0] lod_shift;

        begin
            BF16_ADD = 16'h0000; // Default output

            // 提取符號、指數和尾數
            {A_sign, A_exp, A_min} = A;
            {B_sign, B_exp, B_min} = B;

            // 計算指數差並對齊小數部分
            if(A_exp > B_exp) begin
                Exp_diff = A_exp - B_exp;
                Result_exp = A_exp;
                A_min_aligned = {1'b1, A_min};
                B_min_aligned = {1'b1, B_min} >> Exp_diff;  
            end
            else begin
                Exp_diff = B_exp - A_exp;
                Result_exp = B_exp;
                A_min_aligned = {1'b1, A_min} >> Exp_diff;
                B_min_aligned = {1'b1, B_min};
            end   

            // 進行加減法
            if(A_sign == B_sign) begin // 符號相同直接相加
                    Result_add = A_min_aligned + B_min_aligned;
                    Result_sign = A_sign;
            end
            else begin // 符號不同執行減法
                if(A_min_aligned >= B_min_aligned) begin
                    Result_add = A_min_aligned - B_min_aligned;
                    Result_sign = A_sign;
                end
                else begin
                    Result_add = B_min_aligned - A_min_aligned;
                    Result_sign = B_sign;
                end
            end

            // 正規化 
            if(Result_add[`MIN_WIDTH+1]) begin // 最高位為1，需右移
                Result_add = Result_add >> 1;
                Result_min = Result_add[`MIN_WIDTH-1 -: `MIN_WIDTH]; // 隱藏 1 並 Truncation
                Result_exp = Result_exp + 1;  // 指數加1
                BF16_ADD = {Result_sign, Result_exp, Result_min};
            end
            else if(Result_add == 0) begin
                Result_min = 0;
                BF16_ADD = 16'h0000;
            end
            else begin // LOD: 找 leading 1，左移讓 implicit 1 回到 bit7
                lod_shift = LOD(Result_add[`MIN_WIDTH:0]);
                if(Result_exp > lod_shift) begin // 假設指數不夠扣的話，就會 Underflow
                    Result_add = Result_add << lod_shift;
                    Result_exp = Result_exp - lod_shift;
                    Result_min = Result_add[`MIN_WIDTH-1 -: `MIN_WIDTH];
                    BF16_ADD = {Result_sign, Result_exp, Result_min};
                end
                else BF16_ADD = 16'h0000; // underflow
            end
        end
    endfunction

    // BF16 Multiplication Function
    function automatic [`IO_WIDTH-1:0] BF16_MUL;
        input [`IO_WIDTH-1:0] A, B;

        logic A_sign, B_sign;
        logic [`EXP_WIDTH-1:0] A_exp, B_exp;
        logic [`MIN_WIDTH-1:0] A_min, B_min;
        logic [(`MIN_WIDTH+1)*2-1:0] Result_mul; 
        logic [`MIN_WIDTH-1:0] Result_min;
        logic Result_sign;
        logic [`EXP_WIDTH:0] Exp_add;
        logic [`EXP_WIDTH:0] Result_exp_wide;
        
        begin 
            BF16_MUL = 16'h0000; // Default output

            // 提取符號、指數和尾數
            {A_sign, A_exp, A_min} = A;
            {B_sign, B_exp, B_min} = B;

            // 計算符號
            Result_sign = A_sign ^ B_sign;

            // Significand Multiplication
            Result_mul = {1'b1, A_min} * {1'b1, B_min};

            // Exponent Addition (需要注意，我這邊採用無號數來做運算)
            Exp_add = {1'b0, A_exp} + {1'b0, B_exp}; // 先做無號數加法
            Result_exp_wide = Exp_add - 127; // 減去 Bias (127)

            // 正規化
            if(Result_mul[(`MIN_WIDTH+1)*2-1]) begin // 最高位為1，需右移
                Result_mul = Result_mul >> 1;
                Result_min = Result_mul[(`MIN_WIDTH+1)*2-3 -: `MIN_WIDTH]; // 隱藏 1 並 Truncation
                Result_exp_wide = Result_exp_wide + 9'd1;  // 指數加1
            end
            else Result_min = Result_mul[(`MIN_WIDTH+1)*2-3 -: `MIN_WIDTH]; // 隱藏 1 並 Truncation

            // 處理指數 Overflow 和 Underflow (扣掉 Bias 後的結果小於等於 0 或大於等於 255 都視為 Overflow / Underflow)
            if (Result_exp_wide[8] || Result_exp_wide == 9'd0) BF16_MUL = 16'h0000; // Underflow
            else if (Result_exp_wide >= 9'd255) BF16_MUL = {Result_sign, 8'hFE, 7'h7F}; // Overflow
            else BF16_MUL = {Result_sign, Result_exp_wide[7:0], Result_min};
        end
    endfunction

    /* 這裡不選擇單純採用 LOD 因為出來是 One-Hot Code，最終還是要用 priority encoder 
    function automatic [`MIN_WIDTH-1:0] LOD
        input [`MIN_WIDTH-1:0] In;
        logic [`MIN_WIDTH-1:1] MUX_TEMP;
        begin
            for(int i=`MIN_WIDTH-1; i>=0; i--) begin
                if(i==MIN_WIDTH-1) begin
                    MUX_TEMP[i] = ~In[i];
                    LOD[i] = In[i];
                end
                else begin
                    if(i!=0) MUX_TEMP[i] = (In[i])? 0 : MUX_TEMP[i+1];
                    LOD[i] = MUX_TEMP[i+1] && In[i]; 
                end
            end    
        end
    endfunction*/
endpackage