# OpenSoC-32: Final Physical Verification

set pdk_dir "$::env(PDK_ROOT)/$::env(PDK)"

read_lef "$pdk_dir/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
read_lef "$pdk_dir/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"

read_db results/antenna_detailed_route/soc_top_antenna_detailed_route.odb

file mkdir reports/final_verification

puts "===== FINAL VDD CONNECTIVITY CHECK ====="
check_power_grid -net VDD -dont_require_terminals

puts "===== FINAL VSS CONNECTIVITY CHECK ====="
check_power_grid -net VSS -dont_require_terminals

puts "===== FINAL PLACEMENT CHECK ====="
check_placement -verbose

puts "===== FINAL ANTENNA CHECK ====="
check_antennas -report_file reports/final_verification/final_antenna.rpt

puts "===== FINAL PHYSICAL VERIFICATION COMPLETED ====="
