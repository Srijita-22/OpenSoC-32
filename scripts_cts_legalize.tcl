# OpenSoC-32: Legalize CTS Buffers and Dummy Loads

set pdk_dir "$::env(PDK_ROOT)/$::env(PDK)"

read_lef "$pdk_dir/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
read_lef "$pdk_dir/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"

read_db results/cts/soc_top_cts_power_connected.odb

puts "===== LEGALIZING POST-CTS CELLS ====="

detailed_placement -incremental
check_placement -verbose

file mkdir results/cts_legalized

write_db results/cts_legalized/soc_top_cts_legalized.odb
write_def results/cts_legalized/soc_top_cts_legalized.def

puts "===== CTS LEGALIZATION COMPLETED ====="
