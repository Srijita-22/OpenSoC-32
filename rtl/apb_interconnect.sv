
module apb_interconnect #(
    parameter int ADDR_WIDTH = 12,
    parameter int DATA_WIDTH = 32
) (
    // APB Master interface
    input  logic                  m_psel,
    input  logic                  m_penable,
    input  logic                  m_pwrite,
    input  logic [ADDR_WIDTH-1:0] m_paddr,
    input  logic [DATA_WIDTH-1:0] m_pwdata,
    output logic [DATA_WIDTH-1:0] m_prdata,
    output logic                  m_pready,
    output logic                  m_pslverr,

    // GPIO APB Slave interface
    output logic                  gpio_psel,
    output logic                  gpio_penable,
    output logic                  gpio_pwrite,
    output logic [7:0]            gpio_paddr,
    output logic [DATA_WIDTH-1:0] gpio_pwdata,
    input  logic [DATA_WIDTH-1:0] gpio_prdata,
    input  logic                  gpio_pready,
    input  logic                  gpio_pslverr,

    // UART APB Slave interface
    output logic                  uart_psel,
    output logic                  uart_penable,
    output logic                  uart_pwrite,
    output logic [7:0]            uart_paddr,
    output logic [DATA_WIDTH-1:0] uart_pwdata,
    input  logic [DATA_WIDTH-1:0] uart_prdata,
    input  logic                  uart_pready,
    input  logic                  uart_pslverr,

    // Timer APB Slave interface
    output logic                  timer_psel,
    output logic                  timer_penable,
    output logic                  timer_pwrite,
    output logic [7:0]            timer_paddr,
    output logic [DATA_WIDTH-1:0] timer_pwdata,
    input  logic [DATA_WIDTH-1:0] timer_prdata,
    input  logic                  timer_pready,
    input  logic                  timer_pslverr
);

    // Address regions
    localparam logic [3:0] GPIO_REGION  = 4'h0;
    localparam logic [3:0] UART_REGION  = 4'h1;
    localparam logic [3:0] TIMER_REGION = 4'h2;

    // Internal address decode
    logic [3:0] address_region;

    assign address_region = m_paddr[11:8];

    // Address decoder
    always @(*) begin
        gpio_psel  = 1'b0;
        uart_psel  = 1'b0;
        timer_psel = 1'b0;

        if (m_psel) begin
            case (address_region)
                GPIO_REGION:
                    gpio_psel = 1'b1;

                UART_REGION:
                    uart_psel = 1'b1;

                TIMER_REGION:
                    timer_psel = 1'b1;

                default: begin
                    // No peripheral selected
                end
            endcase
        end
    end

    // Forward control signals only to selected peripheral
    assign gpio_penable  = gpio_psel && m_penable;
    assign uart_penable  = uart_psel && m_penable;
    assign timer_penable = timer_psel && m_penable;

    assign gpio_pwrite = gpio_psel && m_pwrite;
    assign uart_pwrite = uart_psel && m_pwrite;
    assign timer_pwrite = timer_psel && m_pwrite;

    // Forward local address and write data
    assign gpio_paddr  = m_paddr[7:0];
    assign uart_paddr  = m_paddr[7:0];
    assign timer_paddr = m_paddr[7:0];

    assign gpio_pwdata  = m_pwdata;
    assign uart_pwdata  = m_pwdata;
    assign timer_pwdata = m_pwdata;

    // Read data and response multiplexer
    always @(*) begin
        m_prdata  = '0;
        m_pready  = 1'b1;
        m_pslverr = 1'b0;

        if (m_psel && m_penable) begin
            case (address_region)

                GPIO_REGION: begin
                    m_prdata  = gpio_prdata;
                    m_pready  = gpio_pready;
                    m_pslverr = gpio_pslverr;
                end

                UART_REGION: begin
                    m_prdata  = uart_prdata;
                    m_pready  = uart_pready;
                    m_pslverr = uart_pslverr;
                end

                TIMER_REGION: begin
                    m_prdata  = timer_prdata;
                    m_pready  = timer_pready;
                    m_pslverr = timer_pslverr;
                end

                default: begin
                    m_prdata  = '0;
                    m_pready  = 1'b1;
                    m_pslverr = 1'b1;
                end
            endcase
        end
    end

endmodule
