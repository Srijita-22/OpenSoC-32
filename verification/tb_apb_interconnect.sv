
`timescale 1ns/1ps

module tb_apb_interconnect;

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
    logic                  gpio_psel, gpio_penable, gpio_pwrite;
    logic [7:0]            gpio_paddr;
    logic [DATA_WIDTH-1:0] gpio_pwdata, gpio_prdata;
    logic                  gpio_pready, gpio_pslverr;

    // UART signals
    logic                  uart_psel, uart_penable, uart_pwrite;
    logic [7:0]            uart_paddr;
    logic [DATA_WIDTH-1:0] uart_pwdata, uart_prdata;
    logic                  uart_pready, uart_pslverr;

    // Timer signals
    logic                  timer_psel, timer_penable, timer_pwrite;
    logic [7:0]            timer_paddr;
    logic [DATA_WIDTH-1:0] timer_pwdata, timer_prdata;
    logic                  timer_pready, timer_pslverr;

    // SPI signals
    logic                  spi_psel, spi_penable, spi_pwrite;
    logic [7:0]            spi_paddr;
    logic [DATA_WIDTH-1:0] spi_pwdata, spi_prdata;
    logic                  spi_pready, spi_pslverr;

    // DUT
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
        .timer_pslverr(timer_pslverr),

        .spi_psel(spi_psel),
        .spi_penable(spi_penable),
        .spi_pwrite(spi_pwrite),
        .spi_paddr(spi_paddr),
        .spi_pwdata(spi_pwdata),
        .spi_prdata(spi_prdata),
        .spi_pready(spi_pready),
        .spi_pslverr(spi_pslverr)
    );

    // VCD generation
    initial begin
        $dumpfile("results/apb_interconnect.vcd");
        $dumpvars(0, tb_apb_interconnect);
    end

    initial begin

        // Initialize master
        m_psel    = 1'b0;
        m_penable = 1'b0;
        m_pwrite  = 1'b0;
        m_paddr   = '0;
        m_pwdata  = '0;

        // Initialize GPIO response
        gpio_prdata  = 32'h0000_00A5;
        gpio_pready  = 1'b1;
        gpio_pslverr = 1'b0;

        // Initialize UART response
        uart_prdata  = 32'h0000_0055;
        uart_pready  = 1'b1;
        uart_pslverr = 1'b0;

        // Initialize Timer response
        timer_prdata  = 32'h0000_1234;
        timer_pready  = 1'b1;
        timer_pslverr = 1'b0;

        // Initialize SPI response
        spi_prdata  = 32'h0000_003C;
        spi_pready  = 1'b1;
        spi_pslverr = 1'b0;

        #10;

        $display("----------------------------------");
        $display("Starting APB Interconnect Tests");
        $display("----------------------------------");

        // TEST 1: GPIO address decoding
        m_psel = 1'b1;
        m_paddr = 12'h008;
        #1;

        if ({gpio_psel, uart_psel, timer_psel, spi_psel} !== 4'b1000)
            $fatal(1, "GPIO ADDRESS DECODE FAILED");

        if (gpio_paddr !== 8'h08)
            $fatal(1, "GPIO LOCAL ADDRESS FAILED");

        $display("TEST 1 PASSED: GPIO address decoding");

        // TEST 2: UART address decoding
        m_paddr = 12'h108;
        #1;

        if ({gpio_psel, uart_psel, timer_psel, spi_psel} !== 4'b0100)
            $fatal(1, "UART ADDRESS DECODE FAILED");

        if (uart_paddr !== 8'h08)
            $fatal(1, "UART LOCAL ADDRESS FAILED");

        $display("TEST 2 PASSED: UART address decoding");

        // TEST 3: Timer address decoding
        m_paddr = 12'h208;
        #1;

        if ({gpio_psel, uart_psel, timer_psel, spi_psel} !== 4'b0010)
            $fatal(1, "TIMER ADDRESS DECODE FAILED");

        if (timer_paddr !== 8'h08)
            $fatal(1, "TIMER LOCAL ADDRESS FAILED");

        $display("TEST 3 PASSED: Timer address decoding");

        // TEST 4: SPI address decoding
        m_paddr = 12'h308;
        #1;

        if ({gpio_psel, uart_psel, timer_psel, spi_psel} !== 4'b0001)
            $fatal(1, "SPI ADDRESS DECODE FAILED");

        if (spi_paddr !== 8'h08)
            $fatal(1, "SPI LOCAL ADDRESS FAILED");

        $display("TEST 4 PASSED: SPI address decoding");

        // Enable APB access phase for response tests
        m_penable = 1'b1;

        // TEST 5: GPIO read-data routing
        m_paddr = 12'h000;
        #1;

        if (m_prdata !== 32'h0000_00A5)
            $fatal(1, "GPIO READ DATA ROUTING FAILED");

        $display("TEST 5 PASSED: GPIO read-data routing");

        // TEST 6: UART read-data routing
        m_paddr = 12'h100;
        #1;

        if (m_prdata !== 32'h0000_0055)
            $fatal(1, "UART READ DATA ROUTING FAILED");

        $display("TEST 6 PASSED: UART read-data routing");

        // TEST 7: Timer read-data routing
        m_paddr = 12'h200;
        #1;

        if (m_prdata !== 32'h0000_1234)
            $fatal(1, "TIMER READ DATA ROUTING FAILED");

        $display("TEST 7 PASSED: Timer read-data routing");

        // TEST 8: SPI read-data routing
        m_paddr = 12'h300;
        #1;

        if (m_prdata !== 32'h0000_003C)
            $fatal(1, "SPI READ DATA ROUTING FAILED");

        $display("TEST 8 PASSED: SPI read-data routing");

        // TEST 9: SPI PREADY response routing
        spi_pready = 1'b0;
        #1;

        if (m_pready !== 1'b0)
            $fatal(1, "SPI PREADY ROUTING FAILED");

        spi_pready = 1'b1;
        $display("TEST 9 PASSED: SPI PREADY routing");

        // TEST 10: SPI PSLVERR response routing
        spi_pslverr = 1'b1;
        #1;

        if (m_pslverr !== 1'b1)
            $fatal(1, "SPI PSLVERR ROUTING FAILED");

        spi_pslverr = 1'b0;
        $display("TEST 10 PASSED: SPI PSLVERR routing");

        // TEST 11: Invalid address
        m_paddr = 12'h408;
        #1;

        if ({gpio_psel, uart_psel, timer_psel, spi_psel} !== 4'b0000)
            $fatal(1, "INVALID ADDRESS SELECTED A PERIPHERAL");

        if (m_pslverr !== 1'b1)
            $fatal(1, "INVALID ADDRESS ERROR FAILED");

        $display("TEST 11 PASSED: Invalid address detection");

        // TEST 12: No selection when master PSEL is low
        m_psel = 1'b0;
        #1;

        if ({gpio_psel, uart_psel, timer_psel, spi_psel} !== 4'b0000)
            $fatal(1, "PERIPHERAL SELECT ACTIVE WHEN MASTER PSEL IS LOW");

        $display("TEST 12 PASSED: Master deselection");

        // TEST 13: SPI control and write-data routing
        m_psel = 1'b1;
        m_penable = 1'b1;
        m_pwrite = 1'b1;
        m_paddr = 12'h308;
        m_pwdata = 32'h0000_00AB;
        #1;

        if (spi_penable !== 1'b1 || spi_pwrite !== 1'b1)
            $fatal(1, "SPI CONTROL SIGNAL ROUTING FAILED");

        if (gpio_penable !== 1'b0 ||
            uart_penable !== 1'b0 ||
            timer_penable !== 1'b0)
            $fatal(1, "UNSELECTED PERIPHERAL RECEIVED PENABLE");

        if (spi_pwdata !== 32'h0000_00AB)
            $fatal(1, "SPI WRITE DATA ROUTING FAILED");

        $display("TEST 13 PASSED: SPI control and write-data routing");

        $display("----------------------------------");
        $display("ALL APB INTERCONNECT TESTS PASSED!");
        $display("----------------------------------");

        #10;
        $finish;
    end

endmodule

