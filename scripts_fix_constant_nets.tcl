# OpenSoC-32: Correct Yosys constant-net signal types
# Run after initial global routing and before detailed routing.

set pdk_dir "$::env(PDK_ROOT)/$::env(PDK)"

read_lef "$pdk_dir/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
read_lef "$pdk_dir/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"

read_db results/global_route/soc_top_global_route.odb

puts "===== CORRECTING CONSTANT NET TYPES ====="

set block [ord::get_db_block]

set one_net [odb::dbBlock_findNet $block one_]
set zero_net [odb::dbBlock_findNet $block zero_]

if {$one_net == "NULL" || $zero_net == "NULL"} {
    error "Could not find one_ or zero_ constant net"
}

odb::dbNet_setSigType $one_net SIGNAL
odb::dbNet_setSigType $zero_net SIGNAL

file mkdir results/global_route_fixed

write_db results/global_route_fixed/soc_top_global_route_fixed.odb

puts "one_ and zero_ corrected to SIGNAL"
puts "===== CONSTANT NET CORRECTION COMPLETED ====="
