# 1. Library Setup
set search_path "/home/B11130007/Desktop/DSP-In-VLSI/lib $search_path"
set target_library "slow.db tpzn90gv3wc.db"
set link_library   "* $target_library fast.db tpzn90gv3bc.db"

# 2. Read Gate-Level Netlist
read_verilog ../02_SYN/Netlist/Interpolator_syn.v
current_design Interpolator
link_design

# 3. Apply Constraints (SDC)
read_sdc ../02_SYN/Netlist/Interpolator.sdc

# 4. Enable Power Analysis (PT-PX)
set power_enable_analysis true

# 5. Apply Switching Activity (SAIF)
read_saif -strip_path TESTBED/DUT ../03_GATESIM/wave.saif

# 6. Set Operating Conditions (worst case)
set_operating_conditions slow -library slow

# 7. Update Timing & Power
update_timing
update_power

# 8. Reports
sh mkdir -p Report

redirect Report/power.rpt      { report_power }
redirect Report/power_hier.rpt { report_power -hierarchy }
redirect Report/timing.rpt     { report_timing }

