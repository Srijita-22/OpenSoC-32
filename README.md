# OpenSoC-32
### 32-bit System-on-Chip Design and RTL-to-Physical Implementation

OpenSoC-32 is a SystemVerilog-based SoC project featuring an APB peripheral subsystem. It demonstrates RTL design, functional verification, synthesis, timing analysis and physical implementation using open-source EDA tools and the SKY130B PDK.

## 1. Project Features

- 32-bit SoC top-level integration
- APB-based peripheral interconnect
- GPIO, UART, SPI and Timer peripherals
- SystemVerilog RTL and self-checking testbenches
- RTL linting and functional simulation
- Yosys synthesis and SKY130 standard-cell mapping
- Static timing analysis
- Floorplanning and I/O pin placement
- Standard-cell placement and legalization
- Power distribution network generation
- Clock tree synthesis
- Global and detailed routing
- Antenna violation repair
- Post-route timing and physical verification

## 2. Architecture

The SoC uses an APB-based interconnect to connect the master interface to its peripheral subsystem.

### RTL Modules

| Module | Description |
|---|---|
| soc_top.sv | Top-level SoC integration |
| apb_interconnect.sv | APB address decoding and interconnect |
| gpio_apb.sv | GPIO peripheral |
| uart_apb.sv | UART peripheral |
| spi_master_apb.sv | SPI master |
| timer_apb.sv | APB timer |
| counter.sv | Counter module |

## 3. EDA Tools and Technology

| Purpose | Tool |
|---|---|
| RTL design | SystemVerilog |
| RTL linting | Verilator |
| Simulation | Icarus Verilog |
| Waveform analysis | GTKWave |
| Logic synthesis | Yosys |
| Static timing analysis | OpenSTA |
| Physical implementation | OpenROAD |
| PDK | SKY130B |
| Standard-cell library | sky130_fd_sc_hd |
| Environment | Ubuntu 24.04 / WSL |

## 4. Functional Verification

The integrated SoC testbench is located at:

`verification/tb_soc_top.sv`

The full-system testbench completed 13 tests successfully.

Verified functionality includes:

- Reset behavior
- GPIO read and write operations
- UART configuration and operation
- Timer operation
- SPI master operation
- Invalid APB address handling

**Result: 13/13 system tests passed.**

RTL linting was also completed successfully using Verilator with `soc_top` as the top module.

## 5. Synthesis Results

The RTL was synthesized using Yosys and mapped to the SKY130 standard-cell library.

| Metric | Result |
|---|---:|
| Mapped standard-cell instances | 1,836 |
| Wire bits | 2,859 |
| Sequential cells | 320 |
| Mapped cell area | 18,162.4192 µm² |

The mapped design passed Yosys structural checks with zero reported problems.

## 6. Timing Constraints

| Parameter | Value |
|---|---:|
| Clock frequency | 50 MHz |
| Clock period | 20 ns |
| Clock uncertainty | 0.2 ns |
| Input delay | 2 ns |
| Output delay | 2 ns |
| Input transition | 0.1 ns |
| Output load | 0.05 pF |

The asynchronous active-low reset is excluded from ordinary timing analysis using a false-path constraint.

## 7. Physical Design Flow

Physical implementation was performed using OpenROAD and the SKY130B PDK.

The major implementation stages were:

1. Floorplan initialization
2. I/O pin placement
3. Global placement
4. Detailed placement and legalization
5. Power and ground net creation
6. Initial power distribution network generation
7. Clock tree synthesis
8. CTS power reconnection and legalization
9. Post-CTS PDN regeneration
10. Global routing
11. Constant-net signal-type correction
12. Corrected global routing
13. Detailed routing
14. Antenna violation detection and repair
15. Incremental global routing after antenna repair
16. Final detailed routing
17. Post-route timing analysis
18. Final physical verification

### Physical Implementation Configuration

| Parameter | Result |
|---|---:|
| Technology | SKY130B |
| Die dimensions | 300 × 300 µm |
| Core dimensions | Approximately 279.68 × 277.44 µm |
| Initial mapped cell area | 18,162.42 µm² |
| Initial floorplan utilization | 23.4% |
| Clock frequency | 50 MHz |
| CTS clock buffers created | 49 |
| Antenna diodes inserted | 29 |

## 8. Final Implementation Results

### Routing

- Final detailed routing completed successfully.
- TritonRoute final violation count: 0.
- Final detailed-route wire length: approximately 74,387 µm.
- Final detailed-route via count: 16,086.
- Global routing completed with zero reported overflow.

### Antenna Verification

| Check | Result |
|---|---:|
| Net violations | 0 |
| Pin violations | 0 |
| Antenna diodes inserted | 29 |

### Power-Grid Verification

- VDD power-grid shapes connected.
- VSS power-grid shapes connected.
- Final power-grid connectivity checks passed.

### Placement Verification

Final placement legality check completed without reported violations.

### Post-Route Timing

Timing analysis was performed on the final antenna-repaired detailed-route database using estimated global-routing parasitics and the propagated CTS clock.

| Metric | Result |
|---|---:|
| Worst setup slack | +8.45 ns |
| Total negative slack | 0 ns |
| Clock period | 20 ns |
| Estimated clock network delay on worst path | 0.59 ns |

All ten reported worst maximum-delay paths had positive slack.

**Timing qualification:** Parasitics were estimated from global routing. Detailed-route extracted SPEF was not generated, so this result is not extracted-RC signoff timing.

## 9. Physical Verification Status

| Verification | Status |
|---|---|
| RTL functional verification | Passed |
| RTL lint | Passed |
| Yosys structural checks | Passed |
| Placement legality | Passed |
| Power-grid connectivity | Passed |
| Final detailed routing | Zero router violations |
| Antenna checks | Zero net and pin violations |
| Estimated post-route setup timing | Positive slack |
| Foundry signoff DRC | Not completed |
| LVS | Not completed |
| Extracted-RC timing signoff | Not completed |
| Final GDSII generation | Not completed |

OpenROAD routing and antenna checks are implementation-stage checks and should not be interpreted as foundry signoff DRC or LVS results.

## 10. Current Project Status

The integrated SoC has completed functional verification, synthesis, standard-cell mapping, clock-tree synthesis, detailed routing, antenna repair, estimated post-route timing analysis and final implementation-stage physical checks.

Further work includes final GDSII generation, foundry signoff DRC, LVS and extracted-RC timing analysis.

## 11. Repository Structure

- `rtl/` — SystemVerilog RTL modules
- `verification/` — Peripheral and full-system testbenches
- `constraints/` — Timing constraint files
- `scripts_*.tcl` — OpenROAD physical-design and verification scripts
- `results/` — Generated synthesis and physical-design outputs (Git-ignored)
- `reports/` — Generated implementation and verification reports (Git-ignored)
- `README.md` — Project documentation

## 12. Technology and Tools

- HDL: SystemVerilog
- Simulation: Icarus Verilog
- RTL linting: Verilator
- Synthesis: Yosys
- Static timing analysis: OpenSTA
- Physical implementation: OpenROAD
- PDK: SKY130B
- Standard-cell library: sky130_fd_sc_hd
- Environment: Ubuntu 24.04 / WSL

## Author

OpenSoC-32 is an open-source digital design and physical implementation project developed to demonstrate RTL-to-GDSII implementation concepts using open-source EDA tools.
