
`timescale 1ns/1ps

module tb_spi_master_apb;

    // Clock and reset
    logic pclk;
    logic presetn;

    // APB signals
    logic psel;
    logic penable;
    logic pwrite;
    logic [7:0] paddr;
    logic [31:0] pwdata;

    logic [31:0] prdata;
    logic pready;
    logic pslverr;

    // SPI signals
    logic spi_sclk;
    logic spi_mosi;
    logic spi_miso;
    logic spi_cs_n;

    // Test data
    logic [7:0] tx_data;
    logic [7:0] rx_data;

    integer i;
    integer errors;

    // Simulated SPI slave data
    localparam logic [7:0] SLAVE_DATA = 8'h3C;

    // DUT
    spi_master_apb dut (
        .pclk       (pclk),
        .presetn    (presetn),

        .psel       (psel),
        .penable    (penable),
        .pwrite     (pwrite),
        .paddr      (paddr),
        .pwdata     (pwdata),

        .prdata     (prdata),
        .pready     (pready),
        .pslverr    (pslverr),

        .spi_sclk   (spi_sclk),
        .spi_mosi   (spi_mosi),
        .spi_miso   (spi_miso),
        .spi_cs_n   (spi_cs_n)
    );

    // 50 MHz clock: 20 ns period
    initial begin
        pclk = 1'b0;
        forever #10 pclk = ~pclk;
    end

    // --------------------------------------------
    // APB WRITE TASK
    // --------------------------------------------

    task automatic apb_write(
        input logic [7:0] address,
        input logic [31:0] data
    );
    begin
        @(negedge pclk);
        psel   = 1'b1;
        penable = 1'b0;
        pwrite = 1'b1;
        paddr  = address;
        pwdata = data;

        @(negedge pclk);
        penable = 1'b1;

        @(negedge pclk);
        psel    = 1'b0;
        penable = 1'b0;
        pwrite  = 1'b0;
        paddr   = 8'd0;
        pwdata  = 32'd0;
    end
    endtask

    // --------------------------------------------
    // APB READ TASK
    // --------------------------------------------

    task automatic apb_read(
        input logic [7:0] address,
        output logic [31:0] data
    );
    begin
        @(negedge pclk);
        psel    = 1'b1;
        penable = 1'b0;
        pwrite  = 1'b0;
        paddr   = address;

        @(negedge pclk);
        penable = 1'b1;

        #1;
        data = prdata;

        @(negedge pclk);
        psel    = 1'b0;
        penable = 1'b0;
        paddr   = 8'd0;
    end
    endtask

    // --------------------------------------------
    // SPI SLAVE MODEL
    //
    // Mode 0:
    // Slave presents MISO before rising edge.
    // Master samples MISO on rising edge.
    // --------------------------------------------

    logic [7:0] slave_shift;
    integer slave_bit_count;

    always @(negedge spi_cs_n) begin
        slave_shift = SLAVE_DATA;
        slave_bit_count = 0;
        spi_miso = SLAVE_DATA[7];
    end

    always @(negedge spi_sclk) begin
        if (!spi_cs_n) begin
            if (slave_bit_count < 7) begin
                slave_bit_count = slave_bit_count + 1;
                slave_shift = {slave_shift[6:0], 1'b0};
                spi_miso = slave_shift[7];
            end
        end
    end

    // --------------------------------------------
    // MOSI MONITOR
    // --------------------------------------------

    logic [7:0] observed_mosi;
    integer mosi_bit_count;

    initial begin
        observed_mosi = 8'd0;
        mosi_bit_count = 0;

        forever begin
            @(posedge spi_sclk);

            if (!spi_cs_n) begin
                observed_mosi = {
                    observed_mosi[6:0],
                    spi_mosi
                };

                mosi_bit_count = mosi_bit_count + 1;
            end
        end
    end

    // --------------------------------------------
    // MAIN TEST
    // --------------------------------------------

    initial begin

        errors = 0;

        psel = 0;
        penable = 0;
        pwrite = 0;
        paddr = 0;
        pwdata = 0;

        presetn = 0;
        spi_miso = 1;

        tx_data = 8'hA5;
        rx_data = 8'h00;

        observed_mosi = 8'd0;
        mosi_bit_count = 0;

        slave_shift = 8'd0;
        slave_bit_count = 0;

        $dumpfile("results/spi_master.vcd");
        $dumpvars(0, tb_spi_master_apb);

        $display("------------------------------------");
        $display(" SPI MASTER APB TEST STARTED");
        $display("------------------------------------");

        // TEST 1: Reset
        repeat (5) @(negedge pclk);
        presetn = 1;

        repeat (2) @(negedge pclk);

        if (spi_sclk == 0 && spi_cs_n == 1) begin
            $display("TEST 1 PASSED: Reset");
        end
        else begin
            $display("TEST 1 FAILED: Reset");
            errors = errors + 1;
        end

        // TEST 2: Configure clock divider
        apb_write(8'h08, 32'd25);

        if (dut.clkdiv_reg == 32'd25) begin
            $display("TEST 2 PASSED: Clock divider configuration");
        end
        else begin
            $display("TEST 2 FAILED: Clock divider");
            errors = errors + 1;
        end

        // TEST 3: Invalid zero clock divider
        @(negedge pclk);
        psel = 1;
        penable = 1;
        pwrite = 1;
        paddr = 8'h08;
        pwdata = 32'd0;

        #1;
        if (pslverr) begin
            $display("TEST 3 PASSED: Invalid divider rejected");
        end
        else begin
            $display("TEST 3 FAILED: Invalid divider");
            errors = errors + 1;
        end

        @(negedge pclk);
        psel = 0;
        penable = 0;
        pwrite = 0;
        paddr = 0;
        pwdata = 0;

        // TEST 4: Start SPI transfer
        observed_mosi = 8'd0;
        mosi_bit_count = 0;

        apb_write(8'h00, {24'd0, tx_data});

        $display("SPI transfer started");

        // Wait for transfer completion
        wait (dut.spi_done == 1'b1);
        repeat (2) @(negedge pclk);

        // TEST 5: MOSI data
        if (mosi_bit_count == 8 &&
            observed_mosi == tx_data) begin
            $display("TEST 5 PASSED: MOSI transmitted A5");
        end
        else begin
            $display("TEST 5 FAILED: MOSI");
            $display("Observed MOSI = %h, bits = %0d",
                     observed_mosi, mosi_bit_count);
            errors = errors + 1;
        end

        // TEST 6: MISO received data
        apb_read(8'h00, rx_data);

        if (rx_data == SLAVE_DATA) begin
            $display("TEST 6 PASSED: MISO received 3C");
        end
        else begin
            $display("TEST 6 FAILED: MISO");
            $display("Expected = %h, Received = %h",
                     SLAVE_DATA, rx_data);
            errors = errors + 1;
        end

        // TEST 7: Done status
        apb_read(8'h04, rx_data);

        if (rx_data[1] == 1'b1 &&
            rx_data[0] == 1'b0) begin
            $display("TEST 7 PASSED: SPI done status");
        end
        else begin
            $display("TEST 7 FAILED: SPI status");
            errors = errors + 1;
        end

        // TEST 8: Invalid APB address
        @(negedge pclk);
        psel = 1;
        penable = 1;
        pwrite = 0;
        paddr = 8'h0C;

        #1;
        if (pslverr) begin
            $display("TEST 8 PASSED: Invalid address rejected");
        end
        else begin
            $display("TEST 8 FAILED: Invalid address");
            errors = errors + 1;
        end

        @(negedge pclk);
        psel = 0;
        penable = 0;

        // Final result
        $display("------------------------------------");

        if (errors == 0) begin
            $display("ALL SPI MASTER TESTS PASSED!");
        end
        else begin
            $display("SPI MASTER TESTS FAILED: %0d errors", errors);
        end

        $display("------------------------------------");

        #100;
        $finish;

    end

    // Simulation timeout
    initial begin
        #2_000_000;
        $display("ERROR: Simulation timeout");
        $finish;
    end

endmodule
