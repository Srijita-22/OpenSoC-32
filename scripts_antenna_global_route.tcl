# OpenSoC-32: Global Routing After Antenna Repair

set pdk_dir "$::env(PDK_ROOT)/$::env(PDK)"

read_lef "$pdk_dir/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
read_lef "$pdk_dir/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"
read_liberty "$pdk_dir/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

read_db results/antenna_repair/soc_top_antenna_repaired.odb
read_sdc constraints/soc_top.sdc

set_routing_layers -signal met2-met5 -clock met2-met5
set_wire_rc -signal -layer met2
set_wire_rc -clock -layer met5

file mkdir results/antenna_global_route

puts "===== GLOBAL ROUTING AFTER ANTENNA REPAIR ====="

global_route \
    -guide_file results/antenna_global_route/soc_top_antenna.guide \
    -congestion_iterations 30 \
    -verbose

write_db results/antenna_global_route/soc_top_antenna_global_route.odb
write_def results/antenna_global_route/soc_top_antenna_global_route.def

puts "===== POST-ANTENNA GLOBAL ROUTING COMPLETED ====="
