## DSP in VLSI at NTU (ICDA5003)

**This is the course content for `NTU-ICDA 2026 Spring DSP In VLSI` Lab & Final Project.**  
**It implemented DSP IPs including QRD, FFT, Filters, CORDIC, Interpolator and Sorter in TSMC 16nm.**

## Development Environment
- **Simulation Tools : Xilinx Vivado, Synopsys VCS & Verdi**
- **Synthesis Tool : Synopsys DC Compiler**
- **Hardware Algorithm Performance Analysis : Python**

## VCS Command
### Pre-Synthesis Simulation
You need to change "Design" to your Module Name.
```
vcs -full64 -debug_access+all -sverilog tb_Design.v Design.v -o simv
```
### Post-Synthesis Simulation
```
vcs -full64 -debug_access+all +neg_tchk -v tsmc090.v +sdfverbose -sdf \
    max:Desing:Design.sdf Design_syn.v tb_Design.v \
    -o simv_post
```

| Lab| DSP IP | Area | Clock Frequency | Power | Process | Report |
|:----:|:--------:|:------:|:-----------------:|:-------:|:---------:|:----:|
|1| [Sorter](./HW1-Sorter) | 16942 um² | 333 MHz | 2.4640  mW | TSMC 90nm |[Report](./HW1-Sorter/HW1_Sorter.pdf)|
|2| Interpolator |  um² |  MHz |   mW | TSMC 90nm |
|3| CORDIC |  um² |  MHz | mW| TSMC 90nm |
|4| Filter |  um² |  MHz | mW| TSMC 90nm |
|5| FFT |  um² |  MHz | mW| TSMC 90nm |
|6| QRD |  um² |  MHz | mW| TSMC 90nm |

| Final Project | Area | Clock Frequency | Power | Process | Ranking |
|:----:|:--------:|:------:|:-----------------:|:-------:|:---------:|
|      |          |        |                   |         |           |