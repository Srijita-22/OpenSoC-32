
# OpenSoC-32

An open-source 32-bit System-on-Chip (SoC) development project using SystemVerilog and open-source EDA tools.

## Project Goals

- Design a 32-bit peripheral-based SoC.
- Implement an APB bus interface.
- Develop UART, SPI, GPIO and Timer peripherals.
- Verify RTL using simulation and testbenches.
- Synthesize RTL using Yosys.
- Complete physical design using OpenROAD and Sky130 PDK.
- Generate a final GDSII layout.

## Technology

- HDL: SystemVerilog
- RTL Linting: Verilator
- Simulation: Icarus Verilog
- Waveform Viewer: GTKWave
- Synthesis: Yosys
- Physical Design: OpenROAD / OpenLane
- Technology: SkyWater Sky130

## Project Status

### Completed
- Development environment setup
- Initial 8-bit counter RTL
- Verilator lint verification
- Icarus Verilog simulation
- GTKWave waveform generation

### In Progress
- APB GPIO peripheral
- APB interconnect
- UART and SPI peripherals

## Repository Structure

```text
OpenSoC-32/
├── rtl/
├── verification/
├── results/
├── reports/
├── scripts/
├── docs/
├── README.md
└── .gitignore
```

## Author

Open-source digital design learning and development project.
