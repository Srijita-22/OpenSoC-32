# OpenSoC-32 pre-layout static timing analysis

# SKY130 PDK library
set lib "$::env(PDK_ROOT)/$::env(PDK)/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

read_liberty $lib
read_verilog results/soc_top_sky130_flat.v

link_design soc_top

read_sdc constraints/soc_top.sdc

puts "===== DESIGN AND CONSTRAINT CHECK ====="
check_setup -verbose

puts "===== CLOCK REPORT ====="
report_clock_properties

puts "===== TOP 10 WORST MAXIMUM-DELAY PATHS ====="
report_checks -path_delay max -group_path_count 10

puts "===== WORST MAXIMUM SLACK ====="
report_worst_slack -max

puts "===== TOTAL NEGATIVE SLACK ====="
report_tns

puts "===== OPENSTA ANALYSIS COMPLETE ====="
