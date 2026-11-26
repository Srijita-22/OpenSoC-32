# OpenSoC-32: Final GDSII Stream-Out using KLayout
# Technology: SKY130B / sky130_fd_sc_hd

def_path = File.expand_path("results/antenna_detailed_route/soc_top_antenna_detailed_route.def")
tech_lef = File.join(ENV.fetch("PDK_ROOT"), ENV.fetch("PDK"),
  "libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef")
cell_lef = File.join(ENV.fetch("PDK_ROOT"), ENV.fetch("PDK"),
  "libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef")
cell_gds = File.join(ENV.fetch("PDK_ROOT"), ENV.fetch("PDK"),
  "libs.ref/sky130_fd_sc_hd/gds/sky130_fd_sc_hd.gds")
map_file = File.join(ENV.fetch("PDK_ROOT"), ENV.fetch("PDK"),
  "libs.tech/klayout/tech/sky130B.map")

output_gds = File.expand_path("results/final_gds/soc_top.gds")

[def_path, tech_lef, cell_lef, cell_gds, map_file].each do |f|
  raise "Missing input file: #{f}" unless File.file?(f)
end

puts "===== OpenSoC-32 GDSII STREAM-OUT ====="

layout = RBA::Layout.new
options = RBA::LoadLayoutOptions.new
cfg = options.lefdef_config

cfg.lef_files = [tech_lef, cell_lef]
cfg.macro_layout_files = [cell_gds]
cfg.map_file = map_file
cfg.read_lef_with_def = true
cfg.produce_routing = true
cfg.produce_special_routing = true
cfg.produce_pins = true
cfg.produce_lef_pins = true

options.lefdef_config = cfg

puts "Importing final routed DEF and SKY130 cell geometry..."
layout.read(def_path, options)

top = layout.cell("soc_top")
raise "ERROR: soc_top not found" unless top

instance_count = 0
top.each_inst { |_inst| instance_count += 1 }

raise "Unexpected DBU: #{layout.dbu}" unless (layout.dbu - 0.001).abs < 1e-9

puts "Top cell: #{top.name}"
puts "Cell definitions: #{layout.cells}"
puts "Top-level instances: #{instance_count}"

puts "Writing GDSII: #{output_gds}"
layout.write(output_gds)

raise "GDS output missing or empty" unless File.file?(output_gds) && File.size(output_gds) > 0

puts
puts "===== GDSII ROUND-TRIP VALIDATION ====="

check = RBA::Layout.new
check.read(output_gds)

check_top = check.cell("soc_top")
raise "Round-trip top cell missing" unless check_top

check_count = 0
check_top.each_inst { |_inst| check_count += 1 }

raise "DBU mismatch after GDS read-back" unless (check.dbu - layout.dbu).abs < 1e-9
raise "Instance count mismatch" unless check_count == instance_count

puts "Read-back top cell: #{check_top.name}"
puts "Read-back cell definitions: #{check.cells}"
puts "Read-back top-level instances: #{check_count}"
puts "GDSII file size: #{File.size(output_gds)} bytes"
puts "GDSII STREAM-OUT AND ROUND-TRIP VALIDATION PASSED"
