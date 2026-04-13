# DSP in VLSI at NTU (ICDA5003)

**Course content for `NTU-ICDA 2026 Spring — DSP In VLSI` Lab & Final Project.**
- Implements DSP IPs including QRD, FFT, Filters, CORDIC, Interpolator, and Sorter in TSMC 16nm
- Leverage [**Claude Code Skill**](https://github.com/akira2963753/Gen-Flow-Skill/tree/b23cf35d39efca57c16ab1a9468a70472c95560c) to automate project scaffolding and environment configuration

---

## Development Environment

| Role | Tool |
|:-----|:-----|
| Simulation | Xilinx Vivado, Synopsys VCS & Verdi |
| Synthesis | Synopsys DC Compiler |
| Algorithm Analysis | Python |

---

## Flow Commands

### 00\_Pre — Setup
```bash
dos2unix ./xx_run
chmod +x ./xx_run
./xx_run
```

### 01\_RTL — Behavior Simulation
```bash
vcs -full64 -debug_access+all -R +v2k -f file.f
```

### 02\_SYN — Synthesis
```bash
dc_shell -f syn16.tcl
```

> Shared synthesis scripts for all labs: [Script](./Script/) (`syn16.tcl`, `syn90.tcl`, `syn.sdc`)

### 03\_GATESIM — Gate-Level Simulation
```bash
cp ../02_SYN/Netlist/Design.sdf .
vcs -full64 -debug_access+all -R +v2k -f file.f +neg_tchk +sdfverbose -sdf max:Instance:Design.sdf
```

---

## Lab Results

| Lab | DSP IP | Area | Clock Frequency | Process | Report |
|:---:|:-------|-----:|:---------------:|:-------:|:------:|
| 1 | [Sorter](./HW1-Sorter) | 16942 µm² | 333 MHz | TSMC 90nm | [Report](./HW1-Sorter/HW1_Sorter.pdf) |
| 2 | [Digital Filter](./HW2-Digital_Filter) | 2943 µm² | 1 GHz | TSMC 16nm (ADFP) | [Report](./HW2-Digital_Filter/HW2_Digital_Filter.pdf) |
| 3 | [Interpolator](./HW3-Interpolator) | 3152 µm² | 1 GHz| TSMC 16nm (ADFP)| [Report](./HW3-Interpolator/HW3-Interpolator.pdf)|

