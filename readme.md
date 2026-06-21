# DSP in VLSI at NTU (ICDA5003)

**Course content for `NTU-ICDA 2026 Spring — DSP In VLSI` Lab & Final Project.**
- Implements DSP IPs including QRD, FFT, Filters, CORDIC, Interpolator, Sorter, and EVD in TSMC 16nm
- Leverage [**Claude Code Skill**](https://github.com/akira2963753/Gen-Flow-Skill/tree/main) to automate project scaffolding and environment configuration
- Design Notes: [**Obsidian - Design Notes**](https://publish.obsidian.md/marco/Course/DSP+In+VLSI/Project-Note/Final+Project)

---

## Development Environment

| Role | Tool |
|:-----|:-----|
| Simulation | Xilinx Vivado, Synopsys VCS & Verdi |
| Synthesis | Synopsys DC Compiler |
| Algorithm Analysis | Python |

---

## Final Project

**3×3 symmetric matrix Eigen-Value Decomposition (EVD)** via iterative QR algorithm with CORDIC systolic array — submodule: [Final-EVD](./Final-EVD) ([GitHub](https://github.com/akira2963753/Eigen-Value-Decomposition)).

| Project | DSP IP | Area | Clock Frequency | Report |
|:-------:|:------:|:----:|:---------------:|:------:|
| Final | [EVD](./Final-EVD) | 5078 µm² | ~1.09 GHz | [Report](./Final-EVD/report.pdf) |

## Lab Results
**All Process of the lab is TSMC 16nm (ADFP).**

| Lab | DSP IP | Area | Clock Frequency | Report | Grades |
|:---:|:-------:|:-----:|:---------------:|:------:|:------:|
| 1 | [Sorter](./HW1-Sorter) | 665 µm² | 1 GHz | [Report](./HW1-Sorter/HW1_Sorter.pdf) | 100/100 |
| 2 | [Digital Filter](./HW2-Digital_Filter) | 2943 µm² | 1 GHz | [Report](./HW2-Digital_Filter/HW2_Digital_Filter.pdf) | 195/200 |
| 3 | [Interpolator](./HW3-Interpolator) | 4039 µm² | 1.25 GHz | [Report](./HW3-Interpolator/HW3_Interpolator.pdf) | 200/200 |
| 4 | [CORDIC](./HW4-CORDIC) | 1241 µm² | 1 GHz | [Report](./HW4-CORDIC/HW4_CORDIC.pdf) | 200/200 |
| 5 | [FFT](./HW5-FFT) | 8618 µm² | 1 GHz | [Report](./HW5-FFT/HW5_FFT.pdf) | 200/200 |

