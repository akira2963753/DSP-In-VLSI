# HW5 — 32-point Fast Fourier Transform (FFT)

## 作業目標

實作 32-point **SDF（Single-path Delay Feedback）** 架構的 FFT 處理器，包含：
- Python/Matlab 浮點模擬（驗算用）
- 定點數分析（SQNR ≥ 35 dB）
- Verilog 行為模擬
- 合成至 300 MHz

---

## 架構概述

- **演算法**：Radix-2、Decimation-In-Frequency（DIF）FFT
- **點數**：32 點 → **5 個 pipeline stage**
- **架構**：SDF，serial input / serial output
- **各 Stage 延遲緩衝器大小**：Z⁻¹⁶、Z⁻⁸、Z⁻⁴、Z⁻²、Z⁻¹
- **Twiddle Factor ROM**：ROM32(16相)、ROM16(8相)、ROM8(4相)、ROM4(2相)
- **輸出**：DIF 輸出為 bit-reversed order，需經 bit-reversal 模組還原

---

## 工作項目（Steps）

### Step 1 — Python SDF FFT 浮點模擬（10%）
- 讀取 `FFTInput32.mat` 作為輸入 x₀~x₃₁
- 實作 SDF FFT（5 個 stage，butterfly + bypass 邏輯）
- 輸出 X₀~X₃₁（bit-reversed order）
- 列出 1×32 陣列：[頻域 index, SDF 輸出]

### Step 2 — Bit-reversal 重排 + 驗證（10% + 10%）
- 寫程式將 bit-reversed 輸出還原為正常順序
- 畫出 X₀~X₃₁ 的實部與虛部
- 比較 X₀~X₃₁ 與原始 A₀~A₃₁（誤差需 < 10⁻¹⁰）

### Step 3 — 定點數 SQNR 分析（30%）
- 輸入：自己產生的 96 samples（from set S = {1+j, 1-j, -1+j, -1-j}）
- SQNR = 10·log(E{|Xᵢ|²} / E{|X̂ᵢ - Xᵢ|²})，目標 ≥ 35 dB
- **逐 stage 決定小數位元數（fractional wordlength）**：
  - (a) 量化 Stage 1，掃描 N = 9~18，畫 SQNR vs N
  - (b) 固定 Stage 1，量化 Stage 2，掃描 N = 9~18，畫圖
  - (c)~(d) 依序到 Stage 5（共 5 張圖）
  - (e) 決定所有 ROM twiddle factor 的統一小數位元數，畫 SQNR vs N

### Step 4 — Butterfly/Bypass 控制信號（20%）
- 5-bit counter（計 0~31），同步於輸入 index
- 對每個 stage i 產生 Ctr_i（1: butterfly，0: bypass）
- **規律**：Stage i 的 butterfly 模式由 counter 的第 (log₂N - i) bit 決定
  - Stage 1（Z⁻¹⁶）：counter[4] 為 0 時 bypass，為 1 時 butterfly
  - Stage 2（Z⁻⁸）：counter[3]
  - Stage 3（Z⁻⁴）：counter[2]
  - Stage 4（Z⁻²）：counter[1]
  - Stage 5（Z⁻¹）：counter[0]

### Step 5 — 複數乘法器控制信號（10%）
- 控制 multiplier 的 multiply/bypass（1: 乘法，0: bypass）
- 從 Table I 推導各 stage 的時間排程

### Step 6 — Twiddle Factor ROM 設計（10%）
- ROM32 只存第一象限（0~π/2）的 sin/cos 值，共 **8 個點**（16 相 / 4）
- 利用 sin/cos 對稱性，由 counter 的低位 bits 與正負號邏輯產生完整 16 相
- 畫出 block diagram（LUT + 正負號控制邏輯）

### Step 7 — Ping-Pong Bit-Reversal 模組 Verilog（15%）
- 2 個 memory bank（各 32 words）：Bank A / Bank B 交替寫入與讀出
- 寫入時用 bit-reversed index，讀出時用正常順序 index
- 驗證 timing diagram 如 Fig. 8（SDFOut → 32 clk delay → BROut 正常順序）

### Step 8 — SDF FFT 行為模擬（25%）
- 輸入：`FFTInput32.mat`（自選 wordlength 量化）
- 顯示 timing diagram
- 與 Step 1 結果比較，畫 32 sample 實部/虛部誤差

### Step 9 — 串流驗證（25%）
- 輸入：自己的 96 samples（3 個 FFT symbol）
- 顯示 streaming-in / streaming-out timing diagram（參考 Fig. 9）
- 畫 96 sample 誤差，計算 SQNR

### Step 10 — 合成（無 pipeline，10%）
- 在 input/output 加 D flip-flop
- 合成並回報 critical path delay

### Step 11 — Pipeline 加速合成（25%）
- 目標：**300 MHz**（clock period = 3.33 ns）
- 插入 pipeline registers（各 stage 之間、乘法器前後）
- 顯示 post-synthesis timing diagram
- 畫 96 sample 誤差

---

## 提交規範

- **報告 + Python/Matlab 程式碼** → 上傳 NTUCool
- **Verilog 程式碼** → ADFP server，放在 `[Homework 6]` 資料夾

---

## 檔案結構規劃

```
HW5-FFT/
├── CLAUDE.md
├── FFTInput32.mat          # 助教提供的輸入資料
├── Homework 5.pdf
├── python/
│   ├── sdf_fft.py          # Step 1-2: SDF FFT 浮點模擬
│   └── sqnr_analysis.py    # Step 3: 定點 SQNR 分析
└── verilog/
    ├── PE.v                # Processing Element（butterfly/bypass）
    ├── complex_mult.v      # 複數乘法器（含 bypass）
    ├── twiddle_rom.v       # Twiddle factor ROM + 象限控制
    ├── bit_reversal.v      # Ping-pong bit-reversal buffer
    ├── sdf_fft_32.v        # 頂層 32-point SDF FFT
    └── tb_sdf_fft_32.v     # Testbench
```

---

## 關鍵設計參數

| Stage | 延遲緩衝器 | ROM 大小 | Twiddle Phases | Ctr 來自 counter bit |
|-------|-----------|----------|----------------|----------------------|
| 1     | Z⁻¹⁶     | ROM32    | 16             | counter[4]           |
| 2     | Z⁻⁸      | ROM16    | 8              | counter[3]           |
| 3     | Z⁻⁴      | ROM8     | 4              | counter[2]           |
| 4     | Z⁻²      | ROM4     | 2              | counter[1]           |
| 5     | Z⁻¹      | —（W=1） | 1（trivial）   | counter[0]           |

- 複數乘法：`(a+jb)(c+jd) = (ac-bd) + j(ad+bc)`，需 4 個實數乘法 + 2 個加法
- Stage 5 的 twiddle factor 恆為 W³²⁰ = 1，不需乘法器
- Bit-reversal：32-point → 5-bit index 反轉（bit[4:0] → bit[0:4]）
