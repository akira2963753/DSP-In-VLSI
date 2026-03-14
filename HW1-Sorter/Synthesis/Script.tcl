analyze -format verilog {SelectTopK.v Sort8.v}
elaborate SelectTopK -architecture verilog -library DEFAULT
link
check_design

set_operating_conditions -min fast  -max slow
set_wire_load_model -name tsmc090_wl10 -library slow

create_clock -name clk -period 3   [get_ports clk] 
set_dont_touch_network             [get_clocks clk]
set_fix_hold                       [get_clocks clk]

set_clock_uncertainty       0.5    [get_clocks clk]
set_clock_latency   -source 0      [get_clocks clk]
set_clock_latency           0.1    [get_clocks clk] 
set_clock_transition        0.1    [all_clocks]

set_input_transition        0.2    [all_inputs]
set_input_delay   -max 0.5    -clock clk   [all_inputs]
set_input_delay   -min 0.2  -clock clk   [all_inputs]
set_output_delay  -max 0.5    -clock clk   [all_outputs]
set_output_delay  -min 0.2  -clock clk   [all_outputs]
set_driving_cell -library tpzn90gv3wc -lib_cell PDIDGZ_33 -pin {C} [all_inputs]
set_load [load_of "tpzn90gv3wc/PDO16CDG_33/I"] [all_outputs]

set_max_area        0
set_max_capacitance 0.1 [remove_from_collection [all_inputs] [get_ports clk]]
set_max_fanout      10    [remove_from_collection [all_inputs] [get_ports clk]]
set_max_transition  0.2  [all_inputs]

compile_ultra -no_autoungroup 

report_power > power.log
report_area > area.log
report_area -hierarchy > area_all.log
report_timing > timing.log

remove_design -all


