# OpenSoC-32: Reconnect power pins after CTS

set pdk_root $::env(PDK_ROOT)
set pdk $::env(PDK)
set pdk_dir "$pdk_root/$pdk"

set tech_lef "$pdk_dir/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
set cell_lef "$pdk_dir/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"

read_lef $tech_lef
read_lef $cell_lef

read_db results/cts/soc_top_cts.odb

puts "===== RECONNECTING POST-CTS POWER PINS ====="

add_global_connection -net VDD -pin_pattern {^VPWR$} -power
add_global_connection -net VDD -pin_pattern {^VPB$} -power

add_global_connection -net VSS -pin_pattern {^VGND$} -ground
add_global_connection -net VSS -pin_pattern {^VNB$} -ground

global_connect -verbose

file mkdir results/cts
write_db results/cts/soc_top_cts_power_connected.odb

puts "===== POST-CTS POWER CONNECTION COMPLETED ====="
