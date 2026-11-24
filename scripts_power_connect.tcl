# OpenSoC-32: Create and Connect SKY130 Power Nets

set pdk_dir "$::env(PDK_ROOT)/$::env(PDK)"

read_lef "$pdk_dir/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
read_lef "$pdk_dir/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"

read_db results/placement/soc_top_placed.odb

puts "===== CREATING POWER NETS ====="

set block [ord::get_db_block]

set vdd [odb::dbNet_create $block VDD]
set vss [odb::dbNet_create $block VSS]

odb::dbNet_setSigType $vdd POWER
odb::dbNet_setSigType $vss GROUND

set_voltage_domain -name CORE -power VDD -ground VSS

puts "===== CONNECTING STANDARD-CELL POWER PINS ====="

add_global_connection -net VDD -pin_pattern {^VPWR$} -power
add_global_connection -net VDD -pin_pattern {^VPB$} -power

add_global_connection -net VSS -pin_pattern {^VGND$} -ground
add_global_connection -net VSS -pin_pattern {^VNB$} -ground

global_connect -verbose

file mkdir results/pdn
write_db results/pdn/soc_top_power_connected.odb

puts "===== POWER CONNECTION STAGE COMPLETED ====="
