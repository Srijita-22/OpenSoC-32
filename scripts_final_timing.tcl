# OpenSoC-32: Final Post-Route Timing Analysis

set pdk_dir "$::env(PDK_ROOT)/$::env(PDK)"

read_lef "$pdk_dir/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
read_lef "$pdk_dir/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"
read_liberty "$pdk_dir/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

read_db results/antenna_detailed_route/soc_top_antenna_detailed_route.odb
read_sdc constraints/soc_top.sdc

file mkdir reports/post_route

puts "===== ESTIMATING ROUTING PARASITICS ====="
estimate_parasitics -global_routing

puts "===== PROPAGATING CTS CLOCK ====="
set_propagated_clock [all_clocks]

puts "===== FINAL WORST 10 MAXIMUM-DELAY PATHS ====="
report_checks -path_delay max -group_path_count 10 \
    -fields {capacitance slew fanout input_pin net}

puts "===== FINAL WORST SLACK ====="
report_worst_slack -max

puts "===== FINAL TOTAL NEGATIVE SLACK ====="
report_tns -max

puts "===== FINAL TIMING ANALYSIS COMPLETED ====="
