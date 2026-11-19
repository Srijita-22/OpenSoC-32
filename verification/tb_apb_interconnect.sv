
`timescale 1ns/1ps

module tb_apb_interconnect;

    // Parameters
    localparam int ADDR_WIDTH = 12;
    localparam int DATA_WIDTH = 32;

    // APB Master signals
    logic                  m_psel;
    logic                  m_penable;
    logic                  m_pwrite;
    logic [ADDR_WIDTH-1:0] m_paddr;
    logic [DATA_WIDTH-1:0] m_pwdata;
    logic [DATA_WIDTH-1:0] m_prdata;
    logic                  m_pready;
    logic                  m_pslverr;

    // GPIO signals
    logic                  gpio_psel;
    logic                  gpio_penable;
    logic                  gpio_pwrite;
    logic [7:0]            gpio_paddr;
    logic [DATA_WIDTH-1:0] gpio_pwdata;
    logic [DATA_WIDTH-1:0] gpio_prdata;
    logic                  gpio_pready;
    logic                  gpio_pslverr;

    // UART signals
    logic                  uart_psel;
    logic                  uart_penable;
    logic                  uart_pwrite;
    logic [7:0]            uart_paddr;
    logic [DATA_WIDTH-1:0] uart_pwdata;
    logic [DATA_WIDTH-1:0] uart_prdata;
    logic                  uart_pready;
    logic                  uart_pslverr;

    // Timer signals
    logic                  timer_psel;
    logic                  timer_penable;
    logic                  timer_pwrite;
    logic [7:0]            timer_paddr;
    logic [DATA_WIDTH-1:0] timer_pwdata;
    logic [DATA_WIDTH-1:0] timer_prdata;
    logic                  timer_pready;
    logic                  timer_pslverr;

    // DUT instantiation
    apb_interconnect #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .m_psel(m_psel),
        .m_penable(m_penable),
        .m_pwrite(m_pwrite),
        .m_paddr(m_paddr),
        .m_pwdata(m_pwdata),
        .m_prdata(m_prdata),
        .m_pready(m_pready),
        .m_pslverr(m_pslverr),

        .gpio_psel(gpio_psel),
        .gpio_penable(gpio_penable),
        .gpio_pwrite(gpio_pwrite),
        .gpio_paddr(gpio_paddr),
        .gpio_pwdata(gpio_pwdata),
        .gpio_prdata(gpio_prdata),
        .gpio_pready(gpio_pready),
        .gpio_pslverr(gpio_pslverr),

        .uart_psel(uart_psel),
        .uart_penable(uart_penable),
        .uart_pwrite(uart_pwrite),
        .uart_paddr(uart_paddr),
        .uart_pwdata(uart_pwdata),
        .uart_prdata(uart_prdata),
        .uart_pready(uart_pready),
        .uart_pslverr(uart_pslverr),

        .timer_psel(timer_psel),
        .timer_penable(timer_penable),
        .timer_pwrite(timer_pwrite),
        .timer_paddr(timer_paddr),
        .timer_pwdata(timer_pwdata),
        .timer_prdata(timer_prdata),
        .timer_pready(timer_pready),
        .timer_pslverr(timer_pslverr)
    );

    // VCD generation
    initial begin
        $dumpfile("results/apb_interconnect.vcd");
        $dumpvars(0, tb_apb_interconnect);
    end

    // Initialize and run tests
    initial begin

        // Initialize master signals
        m_psel   = 1'b0;
        m_penable = 1'b0;
        m_pwrite = 1'b0;
        m_paddr  = '0;
        m_pwdata = '0;

        // Initialize GPIO response
        gpio_prdata = 32'h0000_00A5;
        gpio_pready = 1'b1;
        gpio_pslverr = 1'b0;

        // Initialize UART response
        uart_prdata = 32'h0000_0055;
        uart_pready = 1'b1;
        uart_pslverr = 1'b0;

        // Initialize Timer response
        timer_prdata = 32'h0000_1234;
        timer_pready = 1'b1;
        timer_pslverr = 1'b0;

        #10;

        $display("----------------------------------");
        $display("Starting APB Interconnect Tests");
        $display("----------------------------------");

        // TEST 1: GPIO address decoding
        m_psel = 1'b1;
        m_paddr = 12'h008;
        #1;

        if ({gpio_psel, uart_psel, timer_psel} !== 3'b100)
            $fatal(1, "GPIO ADDRESS DECODE FAILED");

        if (gpio_paddr !== 8'h08)
            $fatal(1, "GPIO LOCAL ADDRESS FAILED");

        $display("TEST 1 PASSED: GPIO address decoding");

        // TEST 2: UART address decoding
        m_paddr = 12'h108;
        #1;

        if ({gpio_psel, uart_psel, timer_psel} !== 3'b010)
            $fatal(1, "UART ADDRESS DECODE FAILED");

        if (uart_paddr !== 8'h08)
            $fatal(1, "UART LOCAL ADDRESS FAILED");

        $display("TEST 2 PASSED: UART address decoding");

        // TEST 3: Timer address decoding
        m_paddr = 12'h208;
        #1;

        if ({gpio_psel, uart_psel, timer_psel} !== 3'b001)
            $fatal(1, "TIMER ADDRESS DECODE FAILED");

        if (timer_paddr !== 8'h08)
            $fatal(1, "TIMER LOCAL ADDRESS FAILED");

        $display("TEST 3 PASSED: Timer address decoding");

        // TEST 4: Read-data routing from GPIO
        m_paddr = 12'h000;
        m_penable = 1'b1;
        #1;

        if (m_prdata !== 32'h0000_00A5)
            $fatal(1, "GPIO READ DATA ROUTING FAILED");

        $display("TEST 4 PASSED: GPIO read-data routing");

        // TEST 5: Read-data routing from UART
        m_paddr = 12'h100;
        #1;

        if (m_prdata !== 32'h0000_0055)
            $fatal(1, "UART READ DATA ROUTING FAILED");

        $display("TEST 5 PASSED: UART read-data routing");

        // TEST 6: Read-data routing from Timer
        m_paddr = 12'h200;
        #1;

        if (m_prdata !== 32'h0000_1234)
            $fatal(1, "TIMER READ DATA ROUTING FAILED");

        $display("TEST 6 PASSED: Timer read-data routing");

        // TEST 7: PREADY response routing
        timer_pready = 1'b0;
        #1;

        if (m_pready !== 1'b0)
            $fatal(1, "PREADY ROUTING FAILED");

        timer_pready = 1'b1;
        $display("TEST 7 PASSED: PREADY routing");

        // TEST 8: PSLVERR response routing
        uart_pslverr = 1'b1;
        m_paddr = 12'h100;
        #1;

        if (m_pslverr !== 1'b1)
            $fatal(1, "PSLVERR ROUTING FAILED");

        uart_pslverr = 1'b0;
        $display("TEST 8 PASSED: PSLVERR routing");

        // TEST 9: Invalid address
        m_paddr = 12'h308;
        #1;

        if ({gpio_psel, uart_psel, timer_psel} !== 3'b000)
            $fatal(1, "INVALID ADDRESS SELECTED A PERIPHERAL");

        if (m_pslverr !== 1'b1)
            $fatal(1, "INVALID ADDRESS ERROR FAILED");

        $display("TEST 9 PASSED: Invalid address detection");

        // TEST 10: No peripheral selection when PSEL is low
        m_psel = 1'b0;
        #1;

        if ({gpio_psel, uart_psel, timer_psel} !== 3'b000)
            $fatal(1, "PERIPHERAL SELECT ACTIVE WHEN MASTER PSEL IS LOW");

        $display("TEST 10 PASSED: Master deselection");

        // TEST 11: Selected peripheral control signals
        m_psel = 1'b1;
        m_penable = 1'b1;
        m_pwrite = 1'b1;
        m_paddr = 12'h108;
        m_pwdata = 32'h0000_00AB;
        #1;

        if (uart_penable !== 1'b1 || uart_pwrite !== 1'b1)
            $fatal(1, "UART CONTROL SIGNAL ROUTING FAILED");

        if (gpio_penable !== 1'b0 || timer_penable !== 1'b0)
            $fatal(1, "UNSELECTED PERIPHERAL RECEIVED PENABLE");

        if (uart_pwdata !== 32'h0000_00AB)
            $fatal(1, "UART WRITE DATA ROUTING FAILED");

        $display("TEST 11 PASSED: Control and write-data routing");

        $display("----------------------------------");
        $display("ALL APB INTERCONNECT TESTS PASSED!");
        $display("----------------------------------");

        #10;
        $finish;
    end

endmodule
