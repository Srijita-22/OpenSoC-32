# OpenSoC-32 SKY130 initial floorplanning

# PDK paths
set pdk_root $::env(PDK_ROOT)
set pdk $::env(PDK)
set pdk_dir "$pdk_root/$pdk"

set tech_lef "$pdk_dir/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
set cell_lef "$pdk_dir/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"
set lib "$pdk_dir/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

# Read technology and standard-cell LEF
read_lef $tech_lef
read_lef $cell_lef
read_liberty $lib

# Read synthesized design
read_verilog results/soc_top_sky130_flat.v
link_design soc_top

# Initialize die and core geometry (microns)
initialize_floorplan \
    -die_area {0 0 300 300} \
    -core_area {10 10 290 290} \
    -site unithd

# Generate routing tracks
make_tracks

# Save initial floorplan
file mkdir results/floorplan
write_def results/floorplan/soc_top_floorplan.def
write_db results/floorplan/soc_top_floorplan.odb

puts "========================================"
puts "OpenSoC-32 FLOORPLAN INITIALIZATION DONE"
puts "========================================"
