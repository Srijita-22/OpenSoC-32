# OpenSoC-32 initial timing constraints
# Provisional assumptions for pre-layout STA

# Primary clock: 50 MHz
create_clock -name core_clk -period 20.0 [get_ports pclk]

# Clock uncertainty
set_clock_uncertainty 0.2 [get_clocks core_clk]

# External input delays (excluding clock and asynchronous reset)
set_input_delay 2.0 -clock core_clk \
    [get_ports {m_psel m_penable m_pwrite m_paddr[*] m_pwdata[*] gpio_in[*] uart_rx spi_miso}]

# External output delays
set_output_delay 2.0 -clock core_clk [all_outputs]

# Input signal transition assumption
set_input_transition 0.1 \
    [get_ports {m_psel m_penable m_pwrite m_paddr[*] m_pwdata[*] gpio_in[*] uart_rx spi_miso}]

# External output load assumption: 0.05 pF
set_load 0.05 [all_outputs]

# Asynchronous active-low reset is excluded from ordinary data-path timing
set_false_path -from [get_ports presetn]
