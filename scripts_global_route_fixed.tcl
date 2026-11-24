# OpenSoC-32: Corrected SKY130 Global Routing

set pdk_dir "$::env(PDK_ROOT)/$::env(PDK)"

read_lef "$pdk_dir/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
read_lef "$pdk_dir/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"
read_liberty "$pdk_dir/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

read_db results/global_route_fixed/soc_top_global_route_fixed.odb
read_sdc constraints/soc_top.sdc

set_routing_layers -signal met2-met5 -clock met2-met5
set_wire_rc -signal -layer met2
set_wire_rc -clock -layer met5

file mkdir results/global_route_fixed

puts "===== REGENERATING GLOBAL ROUTING ====="

global_route \
    -guide_file results/global_route_fixed/soc_top_fixed.guide \
    -congestion_iterations 30 \
    -verbose

write_db results/global_route_fixed/soc_top_global_route_rerun.odb
write_def results/global_route_fixed/soc_top_global_route_rerun.def

puts "===== CORRECTED GLOBAL ROUTING COMPLETED ====="
