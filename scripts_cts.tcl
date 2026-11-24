# OpenSoC-32 SKY130 Clock Tree Synthesis

set pdk_root $::env(PDK_ROOT)
set pdk $::env(PDK)
set pdk_dir "$pdk_root/$pdk"

set tech_lef "$pdk_dir/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
set cell_lef "$pdk_dir/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"
set lib "$pdk_dir/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

# Load technology and standard-cell definitions
read_lef $tech_lef
read_lef $cell_lef
read_liberty $lib

# Load the validated PDN database
read_db results/pdn/soc_top_pdn.odb

# Load timing constraints
read_sdc constraints/soc_top.sdc

# Set estimated routing resistance and capacitance
set_wire_rc -signal -layer met2
set_wire_rc -clock -layer met5

# Perform clock tree synthesis using SKY130 clock buffers
puts "===== STARTING CLOCK TREE SYNTHESIS ====="

clock_tree_synthesis \
    -buf_list {sky130_fd_sc_hd__clkbuf_1 sky130_fd_sc_hd__clkbuf_2 sky130_fd_sc_hd__clkbuf_4 sky130_fd_sc_hd__clkbuf_8}

puts "===== CLOCK TREE SYNTHESIS COMPLETED ====="

# Save CTS database and DEF
file mkdir results/cts
write_db results/cts/soc_top_cts.odb
write_def results/cts/soc_top_cts.def

puts "========================================"
puts "OpenSoC-32 CTS STAGE COMPLETED"
puts "========================================"
