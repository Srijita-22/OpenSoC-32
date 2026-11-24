# OpenSoC-32 SKY130 Global Routing

set pdk_dir "$::env(PDK_ROOT)/$::env(PDK)"

read_lef "$pdk_dir/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
read_lef "$pdk_dir/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"
read_liberty "$pdk_dir/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

read_db results/post_cts_pdn/soc_top_post_cts_pdn.odb
read_sdc constraints/soc_top.sdc

# Routing layer limits
set_routing_layers -signal met2-met5 -clock met2-met5

# Routing parasitic estimation
set_wire_rc -signal -layer met2
set_wire_rc -clock -layer met5

file mkdir results/global_route
file mkdir reports

puts "===== STARTING GLOBAL ROUTING ====="

global_route \
    -guide_file results/global_route/soc_top.guide \
    -congestion_iterations 30 \
    -verbose

puts "===== SAVING GLOBAL ROUTING RESULTS ====="

write_db results/global_route/soc_top_global_route.odb
write_def results/global_route/soc_top_global_route.def

puts "===== GLOBAL ROUTING COMPLETED ====="
