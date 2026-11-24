
`timescale 1ns/1ps

module soc_top #(
    parameter int ADDR_WIDTH = 12,
    parameter int DATA_WIDTH = 32,
    parameter int GPIO_WIDTH = 8,
    parameter int CLK_FREQ_HZ = 50_000_000,
    parameter int BAUD_RATE = 9600
) (
    // Clock and reset
    input  logic                  pclk,
    input  logic                  presetn,

    // APB Master Interface
    input  logic                  m_psel,
    input  logic                  m_penable,
    input  logic                  m_pwrite,
    input  logic [ADDR_WIDTH-1:0] m_paddr,
    input  logic [DATA_WIDTH-1:0] m_pwdata,
    output logic [DATA_WIDTH-1:0] m_prdata,
    output logic                  m_pready,
    output logic                  m_pslverr,

    // GPIO Interface
    input  logic [GPIO_WIDTH-1:0] gpio_in,
    output logic [GPIO_WIDTH-1:0] gpio_out,
    output logic [GPIO_WIDTH-1:0] gpio_oe,

    // UART Interface
    output logic                  uart_tx,
    input  logic                  uart_rx,

    // SPI Interface
    output logic                  spi_sclk,
    output logic                  spi_mosi,
    input  logic                  spi_miso,
    output logic                  spi_cs_n,

    // Timer Interrupt
    output logic                  timer_irq
);

    // ------------------------------------------------
    // Internal APB GPIO Signals
    // ------------------------------------------------

    logic gpio_psel;
    logic gpio_penable;
    logic gpio_pwrite;
    logic [7:0] gpio_paddr;
    logic [DATA_WIDTH-1:0] gpio_pwdata;
    logic [DATA_WIDTH-1:0] gpio_prdata;
    logic gpio_pready;
    logic gpio_pslverr;

    // ------------------------------------------------
    // Internal APB UART Signals
    // ------------------------------------------------

    logic uart_psel;
    logic uart_penable;
    logic uart_pwrite;
    logic [7:0] uart_paddr;
    logic [DATA_WIDTH-1:0] uart_pwdata;
    logic [DATA_WIDTH-1:0] uart_prdata;
    logic uart_pready;
    logic uart_pslverr;

    // ------------------------------------------------
    // Internal APB Timer Signals
    // ------------------------------------------------

    logic timer_psel;
    logic timer_penable;
    logic timer_pwrite;
    logic [7:0] timer_paddr;
    logic [DATA_WIDTH-1:0] timer_pwdata;
    logic [DATA_WIDTH-1:0] timer_prdata;
    logic timer_pready;
    logic timer_pslverr;

    // ------------------------------------------------
    // Internal APB SPI Signals
    // ------------------------------------------------

    logic spi_psel;
    logic spi_penable;
    logic spi_pwrite;
    logic [7:0] spi_paddr;
    logic [DATA_WIDTH-1:0] spi_pwdata;
    logic [DATA_WIDTH-1:0] spi_prdata;
    logic spi_pready;
    logic spi_pslverr;

    // ------------------------------------------------
    // APB Interconnect
    // ------------------------------------------------

    apb_interconnect #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH)
    ) u_apb_interconnect (
        .m_psel       (m_psel),
        .m_penable    (m_penable),
        .m_pwrite     (m_pwrite),
        .m_paddr      (m_paddr),
        .m_pwdata     (m_pwdata),
        .m_prdata     (m_prdata),
        .m_pready     (m_pready),
        .m_pslverr    (m_pslverr),

        .gpio_psel    (gpio_psel),
        .gpio_penable (gpio_penable),
        .gpio_pwrite  (gpio_pwrite),
        .gpio_paddr   (gpio_paddr),
        .gpio_pwdata  (gpio_pwdata),
        .gpio_prdata  (gpio_prdata),
        .gpio_pready  (gpio_pready),
        .gpio_pslverr (gpio_pslverr),

        .uart_psel    (uart_psel),
        .uart_penable (uart_penable),
        .uart_pwrite  (uart_pwrite),
        .uart_paddr   (uart_paddr),
        .uart_pwdata  (uart_pwdata),
        .uart_prdata  (uart_prdata),
        .uart_pready  (uart_pready),
        .uart_pslverr (uart_pslverr),

        .timer_psel    (timer_psel),
        .timer_penable (timer_penable),
        .timer_pwrite  (timer_pwrite),
        .timer_paddr   (timer_paddr),
        .timer_pwdata  (timer_pwdata),
        .timer_prdata  (timer_prdata),
        .timer_pready  (timer_pready),
        .timer_pslverr (timer_pslverr),

        .spi_psel    (spi_psel),
        .spi_penable (spi_penable),
        .spi_pwrite  (spi_pwrite),
        .spi_paddr   (spi_paddr),
        .spi_pwdata  (spi_pwdata),
        .spi_prdata  (spi_prdata),
        .spi_pready  (spi_pready),
        .spi_pslverr (spi_pslverr)
    );

    // ------------------------------------------------
    // GPIO Peripheral
    // ------------------------------------------------

    gpio_apb #(
        .GPIO_WIDTH (GPIO_WIDTH),
        .ADDR_WIDTH (8),
        .DATA_WIDTH (DATA_WIDTH)
    ) u_gpio (
        .pclk     (pclk),
        .presetn  (presetn),
        .psel     (gpio_psel),
        .penable  (gpio_penable),
        .pwrite   (gpio_pwrite),
        .paddr    (gpio_paddr),
        .pwdata   (gpio_pwdata),
        .prdata   (gpio_prdata),
        .pready   (gpio_pready),
        .pslverr  (gpio_pslverr),
        .gpio_in  (gpio_in),
        .gpio_out (gpio_out),
        .gpio_oe  (gpio_oe)
    );

    // ------------------------------------------------
    // UART Peripheral
    // ------------------------------------------------

    uart_apb #(
        .CLK_FREQ_HZ (CLK_FREQ_HZ),
        .BAUD_RATE   (BAUD_RATE),
        .ADDR_WIDTH  (8),
        .DATA_WIDTH  (DATA_WIDTH)
    ) u_uart (
        .pclk     (pclk),
        .presetn  (presetn),
        .psel     (uart_psel),
        .penable  (uart_penable),
        .pwrite   (uart_pwrite),
        .paddr    (uart_paddr),
        .pwdata   (uart_pwdata),
        .prdata   (uart_prdata),
        .pready   (uart_pready),
        .pslverr  (uart_pslverr),
        .uart_tx  (uart_tx),
        .uart_rx  (uart_rx)
    );

    // ------------------------------------------------
    // Timer Peripheral
    // ------------------------------------------------

    timer_apb #(
        .ADDR_WIDTH (8),
        .DATA_WIDTH (DATA_WIDTH)
    ) u_timer (
        .pclk      (pclk),
        .presetn   (presetn),
        .psel      (timer_psel),
        .penable   (timer_penable),
        .pwrite    (timer_pwrite),
        .paddr     (timer_paddr),
        .pwdata    (timer_pwdata),
        .prdata    (timer_prdata),
        .pready    (timer_pready),
        .pslverr   (timer_pslverr),
        .timer_irq (timer_irq)
    );

    // ------------------------------------------------
    // SPI Master Peripheral
    // ------------------------------------------------

    spi_master_apb #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (8)
    ) u_spi (
        .pclk      (pclk),
        .presetn   (presetn),
        .psel      (spi_psel),
        .penable   (spi_penable),
        .pwrite    (spi_pwrite),
        .paddr     (spi_paddr),
        .pwdata    (spi_pwdata),
        .prdata    (spi_prdata),
        .pready    (spi_pready),
        .pslverr   (spi_pslverr),
        .spi_sclk  (spi_sclk),
        .spi_mosi  (spi_mosi),
        .spi_miso  (spi_miso),
        .spi_cs_n  (spi_cs_n)
    );

endmodule
