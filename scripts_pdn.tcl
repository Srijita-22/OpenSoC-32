# OpenSoC-32 SKY130 Power Distribution Network

set pdk_root $::env(PDK_ROOT)
set pdk $::env(PDK)
set pdk_dir "$pdk_root/$pdk"

set tech_lef "$pdk_dir/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
set cell_lef "$pdk_dir/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"

# Load technology and standard-cell definitions
read_lef $tech_lef
read_lef $cell_lef

# Load placed design with verified power connections
read_db results/pdn/soc_top_power_connected.odb

# Define the core voltage domain
set_voltage_domain -name CORE -power VDD -ground VSS

# Define the power distribution grid
define_pdn_grid -name core_grid -voltage_domains CORE

# Standard-cell power rails on met1
add_pdn_stripe -grid core_grid \
    -layer met1 \
    -width 0.48 \
    -pitch 2.72 \
    -offset 0 \
    -followpins

# Vertical power straps on met4
add_pdn_stripe -grid core_grid \
    -layer met4 \
    -width 1.6 \
    -pitch 20 \
    -offset 10

# Connect standard-cell rails to vertical straps
add_pdn_connect -grid core_grid -layers {met1 met4}

# Horizontal power straps on met5
add_pdn_stripe -grid core_grid \
    -layer met5 \
    -width 1.6 \
    -pitch 20 \
    -offset 10

# Connect vertical and horizontal straps
add_pdn_connect -grid core_grid -layers {met4 met5}

# Generate the PDN
puts "===== GENERATING OpenSoC-32 PDN ====="
pdngen -verbose

# Save the resulting database and DEF
file mkdir results/pdn
write_db results/pdn/soc_top_pdn.odb
write_def results/pdn/soc_top_pdn.def

puts "========================================"
puts "OpenSoC-32 PDN GENERATION COMPLETED"
puts "========================================"
