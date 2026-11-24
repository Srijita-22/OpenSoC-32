# OpenSoC-32: SKY130 Antenna Repair

set pdk_dir "$::env(PDK_ROOT)/$::env(PDK)"

read_lef "$pdk_dir/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
read_lef "$pdk_dir/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"
read_liberty "$pdk_dir/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

read_db results/detailed_route/soc_top_detailed_route.odb

file mkdir results/antenna_repair
file mkdir reports

puts "===== ANTENNA CHECK BEFORE REPAIR ====="
check_antennas -report_violating_nets

puts "===== INSERTING ANTENNA DIODES ====="
repair_antennas sky130_fd_sc_hd__diode_2 -diode_only

puts "===== LEGALIZING INSERTED DIODES ====="
detailed_placement -incremental
check_placement -verbose

puts "===== ANTENNA CHECK AFTER REPAIR ====="
check_antennas -report_file reports/antenna_after_repair.rpt

write_db results/antenna_repair/soc_top_antenna_repaired.odb
write_def results/antenna_repair/soc_top_antenna_repaired.def

puts "===== ANTENNA REPAIR COMPLETED ====="
