
`timescale 1ns/1ps

module tb_soc_top;

    // ------------------------------------------------
    // Clock and reset
    // ------------------------------------------------
    logic pclk;
    logic presetn;

    // ------------------------------------------------
    // APB master signals
    // ------------------------------------------------
    logic        m_psel;
    logic        m_penable;
    logic        m_pwrite;
    logic [11:0] m_paddr;
    logic [31:0] m_pwdata;

    logic [31:0] m_prdata;
    logic        m_pready;
    logic        m_pslverr;

    // ------------------------------------------------
    // GPIO signals
    // ------------------------------------------------
    logic [7:0] gpio_in;
    logic [7:0] gpio_out;
    logic [7:0] gpio_oe;

    // ------------------------------------------------
    // UART signals
    // ------------------------------------------------
    logic uart_tx;
    logic uart_rx;

    // ------------------------------------------------
    // SPI signals
    // ------------------------------------------------
    logic spi_sclk;
    logic spi_mosi;
    logic spi_miso;
    logic spi_cs_n;

    // ------------------------------------------------
    // Timer signal
    // ------------------------------------------------
    logic timer_irq;

    // ------------------------------------------------
    // Testbench variables
    // ------------------------------------------------
    logic        error;
    logic [31:0] read_data;

    integer test_count;
    integer i;

    // ------------------------------------------------
    // SPI slave model
    // ------------------------------------------------
    localparam logic [7:0] SLAVE_DATA = 8'h3C;

    logic [7:0] slave_shift;
    integer slave_bit_count;

    logic [7:0] observed_mosi;
    integer mosi_bit_count;

    // ------------------------------------------------
    // DUT
    // ------------------------------------------------
    soc_top dut (
        .pclk       (pclk),
        .presetn    (presetn),

        .m_psel     (m_psel),
        .m_penable  (m_penable),
        .m_pwrite   (m_pwrite),
        .m_paddr    (m_paddr),
        .m_pwdata   (m_pwdata),

        .m_prdata   (m_prdata),
        .m_pready   (m_pready),
        .m_pslverr  (m_pslverr),

        .gpio_in    (gpio_in),
        .gpio_out   (gpio_out),
        .gpio_oe    (gpio_oe),

        .uart_tx    (uart_tx),
        .uart_rx    (uart_rx),

        .spi_sclk   (spi_sclk),
        .spi_mosi   (spi_mosi),
        .spi_miso   (spi_miso),
        .spi_cs_n   (spi_cs_n),

        .timer_irq  (timer_irq)
    );

    // ------------------------------------------------
    // Clock generation: 50 MHz
    // ------------------------------------------------
    initial begin
        pclk = 1'b0;
        forever #10 pclk = ~pclk;
    end

    // ------------------------------------------------
    // SPI slave: provide MISO data
    // ------------------------------------------------
    always @(negedge spi_cs_n) begin
        slave_shift     = SLAVE_DATA;
        slave_bit_count = 0;
        spi_miso        = SLAVE_DATA[7];
    end

    always @(negedge spi_sclk) begin
        if (!spi_cs_n) begin
            if (slave_bit_count < 7) begin
                slave_bit_count = slave_bit_count + 1;

                slave_shift = {
                    slave_shift[6:0],
                    1'b0
                };

                spi_miso = slave_shift[7];
            end
        end
    end

    // ------------------------------------------------
    // SPI MOSI monitor
    // ------------------------------------------------
    initial begin
        observed_mosi = 8'd0;
        mosi_bit_count = 0;
    end

    always @(negedge spi_cs_n) begin
        observed_mosi = 8'd0;
        mosi_bit_count = 0;
    end

    always @(posedge spi_sclk) begin
        if (!spi_cs_n) begin
            observed_mosi = {
                observed_mosi[6:0],
                spi_mosi
            };

            mosi_bit_count = mosi_bit_count + 1;
        end
    end

    // ------------------------------------------------
    // APB WRITE TASK
    // Sample PSLVERR during access phase, before
    // the completing rising clock edge.
    // ------------------------------------------------
    task automatic apb_write(
        input  logic [11:0] address,
        input  logic [31:0] data,
        output logic        write_error
    );
    begin
        // Setup phase
        @(negedge pclk);

        m_psel    = 1'b1;
        m_penable = 1'b0;
        m_pwrite  = 1'b1;
        m_paddr   = address;
        m_pwdata  = data;

        // Access phase
        @(negedge pclk);

        m_penable = 1'b1;

        // Sample before transaction completion
        #1;
        write_error = m_pslverr;

        if (!m_pready)
            $display("WARNING: APB write PREADY is low at address %h",
                     address);

        // Complete APB transaction
        @(posedge pclk);

        @(negedge pclk);

        m_psel    = 1'b0;
        m_penable = 1'b0;
        m_pwrite  = 1'b0;
        m_paddr   = 12'h000;
        m_pwdata  = 32'h00000000;
    end
    endtask

    // ------------------------------------------------
    // APB READ TASK
    // ------------------------------------------------
    task automatic apb_read(
        input  logic [11:0] address,
        output logic [31:0] data,
        output logic        read_error
    );
    begin
        // Setup phase
        @(negedge pclk);

        m_psel    = 1'b1;
        m_penable = 1'b0;
        m_pwrite  = 1'b0;
        m_paddr   = address;
        m_pwdata  = 32'h00000000;

        // Access phase
        @(negedge pclk);

        m_penable = 1'b1;

        // Sample before transaction completion
        #1;
        data       = m_prdata;
        read_error = m_pslverr;

        if (!m_pready)
            $display("WARNING: APB read PREADY is low at address %h",
                     address);

        // Complete APB transaction
        @(posedge pclk);

        @(negedge pclk);

        m_psel    = 1'b0;
        m_penable = 1'b0;
        m_pwrite  = 1'b0;
        m_paddr   = 12'h000;
    end
    endtask

    // ------------------------------------------------
    // Main test sequence
    // ------------------------------------------------
    initial begin

        test_count = 0;

        // Initialize signals
        presetn   = 1'b0;

        m_psel    = 1'b0;
        m_penable = 1'b0;
        m_pwrite  = 1'b0;
        m_paddr   = 12'h000;
        m_pwdata  = 32'h00000000;

        gpio_in   = 8'hA5;
        uart_rx   = 1'b1;
        spi_miso  = 1'b0;

        error     = 1'b0;
        read_data = 32'h00000000;

        slave_shift     = 8'h00;
        slave_bit_count = 0;

        observed_mosi = 8'h00;
        mosi_bit_count = 0;

        $display("-------------------------------------");
        $display("OpenSoC-32 FULL SYSTEM TEST STARTED");
        $display("-------------------------------------");

        // ------------------------------------------------
        // TEST 1: System reset
        // ------------------------------------------------
        repeat (3) @(posedge pclk);

        @(negedge pclk);
        presetn = 1'b1;

        repeat (3) @(posedge pclk);
        #1;

        if (gpio_out !== 8'h00)
            $fatal(1, "TEST 1 FAILED: GPIO output reset");

        if (gpio_oe !== 8'h00)
            $fatal(1, "TEST 1 FAILED: GPIO direction reset");

        if (uart_tx !== 1'b1)
            $fatal(1, "TEST 1 FAILED: UART TX reset");

        if (spi_cs_n !== 1'b1)
            $fatal(1, "TEST 1 FAILED: SPI CS reset");

        test_count = test_count + 1;
        $display("TEST 1 PASSED: System reset");

        // ------------------------------------------------
        // TEST 2: GPIO direction
        // ------------------------------------------------
        apb_write(12'h000, 32'h000000FF, error);

        if (error)
            $fatal(1, "TEST 2 FAILED: GPIO direction write error");

        apb_read(12'h000, read_data, error);

        if (error || read_data[7:0] !== 8'hFF)
            $fatal(1, "TEST 2 FAILED: GPIO direction");

        test_count = test_count + 1;
        $display("TEST 2 PASSED: GPIO direction");

        // ------------------------------------------------
        // TEST 3: GPIO output
        // ------------------------------------------------
        apb_write(12'h004, 32'h0000005A, error);

        if (error)
            $fatal(1, "TEST 3 FAILED: GPIO output write error");

        #1;

        if (gpio_out !== 8'h5A)
            $fatal(1, "TEST 3 FAILED: GPIO output value");

        test_count = test_count + 1;
        $display("TEST 3 PASSED: GPIO output");

        // ------------------------------------------------
        // TEST 4: GPIO input
        // ------------------------------------------------
        apb_read(12'h008, read_data, error);

        if (error || read_data[7:0] !== 8'hA5)
            $fatal(1, "TEST 4 FAILED: GPIO input");

        test_count = test_count + 1;
        $display("TEST 4 PASSED: GPIO input");

        // ------------------------------------------------
        // TEST 5: UART baud divider
        // ------------------------------------------------
        apb_write(12'h108, 32'd4, error);

        if (error)
            $fatal(1, "TEST 5 FAILED: UART baud divider write");

        apb_read(12'h108, read_data, error);

        if (error || read_data !== 32'd4)
            $fatal(1, "TEST 5 FAILED: UART baud divider read");

        test_count = test_count + 1;
        $display("TEST 5 PASSED: UART baud divider");

        // ------------------------------------------------
        // TEST 6: UART TX write
        // ------------------------------------------------
        apb_write(12'h100, 32'h000000A5, error);

        if (error)
            $fatal(1, "TEST 6 FAILED: UART TX write");

        // Allow the complete UART frame to transmit
        repeat (60) @(posedge pclk);

        apb_read(12'h104, read_data, error);

        if (error)
            $fatal(1, "TEST 6 FAILED: UART status read");

        if (read_data[0] !== 1'b0)
            $fatal(1, "TEST 6 FAILED: UART TX still busy");

        if (uart_tx !== 1'b1)
            $fatal(1, "TEST 6 FAILED: UART TX did not return idle");

        test_count = test_count + 1;
        $display("TEST 6 PASSED: UART TX transmission");

        // ------------------------------------------------
        // TEST 7: Timer load and countdown
        // ------------------------------------------------
        apb_write(12'h204, 32'd100, error);

        if (error)
            $fatal(1, "TEST 7 FAILED: Timer load write");

        apb_read(12'h208, read_data, error);

        if (error || read_data !== 32'd100)
            $fatal(1, "TEST 7 FAILED: Timer initial value");

        apb_write(12'h200, 32'd1, error);

        if (error)
            $fatal(1, "TEST 7 FAILED: Timer enable");

        repeat (5) @(posedge pclk);

        apb_read(12'h208, read_data, error);

        if (error || read_data >= 32'd100)
            $fatal(1, "TEST 7 FAILED: Timer countdown");

        // Disable timer
        apb_write(12'h200, 32'd0, error);

        if (error)
            $fatal(1, "TEST 7 FAILED: Timer disable");

        test_count = test_count + 1;
        $display("TEST 7 PASSED: Timer load and countdown");

        // ------------------------------------------------
        // TEST 8: Timer interrupt
        // ------------------------------------------------
        apb_write(12'h204, 32'd4, error);

        if (error)
            $fatal(1, "TEST 8 FAILED: Timer reload write");

        // Enable timer and interrupt
        apb_write(12'h200, 32'd3, error);

        if (error)
            $fatal(1, "TEST 8 FAILED: Timer interrupt enable");

        // Detect the one-cycle interrupt pulse
        begin : TIMER_IRQ_CHECK
            logic irq_seen;

            irq_seen = 1'b0;

            for (i = 0; i < 20; i = i + 1) begin
                @(posedge pclk);

                if (timer_irq === 1'b1)
                    irq_seen = 1'b1;
            end

            if (!irq_seen)
                $fatal(1, "TEST 8 FAILED: Timer IRQ not generated");
        end

        // Disable timer before clearing pending status
        apb_write(12'h200, 32'd0, error);

        if (error)
            $fatal(1, "TEST 8 FAILED: Timer disable after IRQ");

        apb_read(12'h20C, read_data, error);

        if (error || read_data[0] !== 1'b1)
            $fatal(1, "TEST 8 FAILED: Timer pending status");

        // Clear pending interrupt
        apb_write(12'h20C, 32'd1, error);

        if (error)
            $fatal(1, "TEST 8 FAILED: Timer interrupt clear write");

        apb_read(12'h20C, read_data, error);

        if (error || read_data[0] !== 1'b0)
            $fatal(1, "TEST 8 FAILED: Timer interrupt not cleared");

        test_count = test_count + 1;
        $display("TEST 8 PASSED: Timer interrupt and clear");

        // ------------------------------------------------
        // TEST 9: SPI clock divider
        // ------------------------------------------------
        apb_write(12'h308, 32'd2, error);

        if (error)
            $fatal(1, "TEST 9 FAILED: SPI clock divider write");

        apb_read(12'h308, read_data, error);

        if (error || read_data !== 32'd2)
            $fatal(1, "TEST 9 FAILED: SPI clock divider read");

        test_count = test_count + 1;
        $display("TEST 9 PASSED: SPI clock divider");

        // ------------------------------------------------
        // TEST 10: SPI transmission
        // ------------------------------------------------
        apb_write(12'h300, 32'h000000A5, error);

        if (error)
            $fatal(1, "TEST 10 FAILED: SPI DATA write");

        // Allow SPI transfer to complete
        repeat (40) @(posedge pclk);

        if (spi_cs_n !== 1'b1)
            $fatal(1, "TEST 10 FAILED: SPI chip select not released");

        if (mosi_bit_count != 8)
            $fatal(1, "TEST 10 FAILED: Incorrect MOSI bit count");

        if (observed_mosi !== 8'hA5)
            $fatal(1, "TEST 10 FAILED: MOSI data mismatch");

        test_count = test_count + 1;
        $display("TEST 10 PASSED: SPI MOSI transmission");

        // ------------------------------------------------
        // TEST 11: SPI received data
        // ------------------------------------------------
        apb_read(12'h300, read_data, error);

        if (error || read_data[7:0] !== SLAVE_DATA)
            $fatal(1, "TEST 11 FAILED: SPI MISO received data");

        test_count = test_count + 1;
        $display("TEST 11 PASSED: SPI MISO reception");

        // ------------------------------------------------
        // TEST 12: SPI completion status
        // ------------------------------------------------
        apb_read(12'h304, read_data, error);

        if (error || read_data[1] !== 1'b1)
            $fatal(1, "TEST 12 FAILED: SPI completion status");

        test_count = test_count + 1;
        $display("TEST 12 PASSED: SPI completion status");

        // ------------------------------------------------
        // TEST 13: Invalid address
        // ------------------------------------------------
        apb_read(12'h408, read_data, error);

        if (!error)
            $fatal(1, "TEST 13 FAILED: Invalid address not detected");

        test_count = test_count + 1;
        $display("TEST 13 PASSED: Invalid address detection");

        // ------------------------------------------------
        // Final result
        // ------------------------------------------------
        $display("-------------------------------------");
        $display("ALL %0d SYSTEM TESTS PASSED!", test_count);
        $display("OpenSoC-32 FULL SYSTEM TEST COMPLETED");
        $display("-------------------------------------");

        $finish;
    end

    // ------------------------------------------------
    // Simulation timeout
    // ------------------------------------------------
    initial begin
        #2000000;
        $fatal(1, "SIMULATION TIMEOUT");
    end

endmodule
