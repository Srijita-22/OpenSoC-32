# OpenSoC-32 SKY130 placement flow

set pdk_root $::env(PDK_ROOT)
set pdk $::env(PDK)
set pdk_dir "$pdk_root/$pdk"

set tech_lef "$pdk_dir/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
set cell_lef "$pdk_dir/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"
set lib "$pdk_dir/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

# Load technology and cell libraries
read_lef $tech_lef
read_lef $cell_lef
read_liberty $lib

# Load completed floorplan
read_db results/pins/soc_top_pins.odb

# Global placement
puts "===== STARTING GLOBAL PLACEMENT ====="
global_placement -density 0.35

# Detailed placement and legalization
puts "===== STARTING DETAILED PLACEMENT ====="
detailed_placement

# Verify placement legality
puts "===== CHECKING PLACEMENT ====="
check_placement -verbose

# Save placement database
file mkdir results/placement
write_def results/placement/soc_top_placed.def
write_db results/placement/soc_top_placed.odb

puts "========================================"
puts "OpenSoC-32 PLACEMENT COMPLETED"
puts "========================================"
