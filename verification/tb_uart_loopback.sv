
`timescale 1ns/1ps

module tb_uart_loopback;

    localparam integer CLK_FREQ_HZ = 50_000_000;
    localparam integer BAUD_RATE   = 9600;
    localparam integer BAUD_DIV    = CLK_FREQ_HZ / BAUD_RATE;

    // APB signals
    logic pclk;
    logic presetn;

    logic psel;
    logic penable;
    logic pwrite;
    logic [7:0] paddr;
    logic [31:0] pwdata;

    logic [31:0] prdata;
    logic pready;
    logic pslverr;

    // UART signals
    logic uart_tx;
    wire uart_rx;

    // Test variables
    integer errors;
    logic [31:0] read_value;

    logic [7:0] test_data;

    // Loopback connection
    assign uart_rx = uart_tx;

    // ------------------------------------------------
    // DUT
    // ------------------------------------------------

    uart_apb #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .pclk(pclk),
        .presetn(presetn),

        .psel(psel),
        .penable(penable),
        .pwrite(pwrite),
        .paddr(paddr),
        .pwdata(pwdata),

        .prdata(prdata),
        .pready(pready),
        .pslverr(pslverr),

        .uart_tx(uart_tx),
        .uart_rx(uart_rx)
    );

    // ------------------------------------------------
    // Clock: 50 MHz
    // ------------------------------------------------

    initial begin
        pclk = 0;
        forever #10 pclk = ~pclk;
    end

    // ------------------------------------------------
    // APB WRITE TASK
    // ------------------------------------------------

    task automatic apb_write(
        input logic [7:0] addr,
        input logic [31:0] data
    );

        begin

            @(negedge pclk);

            psel   = 1'b1;
            penable = 1'b0;
            pwrite = 1'b1;
            paddr  = addr;
            pwdata = data;

            // APB access phase
            @(negedge pclk);

            penable = 1'b1;

            if (pslverr)
                $display("APB WRITE ERROR at address %h", addr);

            @(negedge pclk);

            psel    = 1'b0;
            penable = 1'b0;
            pwrite  = 1'b0;

        end

    endtask

    // ------------------------------------------------
    // APB READ TASK
    // ------------------------------------------------

    task automatic apb_read(
        input logic [7:0] addr,
        output logic [31:0] data
    );

        begin

            @(negedge pclk);

            psel    = 1'b1;
            penable = 1'b0;
            pwrite  = 1'b0;
            paddr   = addr;

            // APB access phase
            @(negedge pclk);

            penable = 1'b1;

            #1;
            data = prdata;

            if (pslverr)
                $display("APB READ ERROR at address %h", addr);

            @(negedge pclk);

            psel    = 1'b0;
            penable = 1'b0;

        end

    endtask

    // ------------------------------------------------
    // MAIN TEST
    // ------------------------------------------------

    initial begin

        $dumpfile("results/uart_loopback.vcd");
        $dumpvars(0, tb_uart_loopback);

        errors = 0;

        pclk = 0;
        presetn = 0;

        psel = 0;
        penable = 0;
        pwrite = 0;
        paddr = 0;
        pwdata = 0;

        test_data = 8'hA5;

        $display("");
        $display("====================================");
        $display("     UART TX/RX LOOPBACK TEST");
        $display("====================================");

        // --------------------------------------------
        // TEST 1: RESET
        // --------------------------------------------

        repeat (5) @(negedge pclk);

        presetn = 1;

        @(negedge pclk);

        if (uart_tx === 1'b1) begin
            $display("PASS: UART TX idle HIGH after reset");
        end
        else begin
            $display("FAIL: UART TX reset");
            errors = errors + 1;
        end

        // --------------------------------------------
        // TEST 2: BAUD DIVIDER
        // --------------------------------------------

        apb_read(8'h08, read_value);

        if (read_value == BAUD_DIV) begin
            $display("PASS: Baud divider = %0d", read_value);
        end
        else begin
            $display("FAIL: Baud divider incorrect: %0d",
                     read_value);
            errors = errors + 1;
        end

        // --------------------------------------------
        // TEST 3: TRANSMIT DATA
        // --------------------------------------------

        $display("");
        $display("Transmitting data: 0x%h", test_data);

        apb_write(8'h00, {24'd0, test_data});

        // --------------------------------------------
        // TEST 4: TX BUSY
        // --------------------------------------------

        apb_read(8'h04, read_value);

        if (read_value[0] == 1'b1) begin
            $display("PASS: TX busy flag detected");
        end
        else begin
            $display("FAIL: TX busy flag not detected");
            errors = errors + 1;
        end

        // --------------------------------------------
        // TEST 5: WAIT FOR TRANSMISSION COMPLETE
        // --------------------------------------------

        wait (dut.tx_done === 1'b1);

        $display("PASS: UART transmission completed");

        // --------------------------------------------
        // TEST 6: RECEIVE DATA
        // --------------------------------------------

        wait (dut.rx_valid === 1'b1);

        $display("PASS: UART RX valid flag detected");

        // --------------------------------------------
        // TEST 7: READ RECEIVED DATA
        // --------------------------------------------

        apb_read(8'h00, read_value);

        $display("Transmitted data : 0x%h", test_data);
        $display("Received data    : 0x%h", read_value[7:0]);

        if (read_value[7:0] == test_data) begin
            $display("PASS: TX/RX loopback data matched");
        end
        else begin
            $display("FAIL: TX/RX loopback data mismatch");
            errors = errors + 1;
        end

        // --------------------------------------------
        // TEST 8: RX VALID CLEARED AFTER READ
        // --------------------------------------------

        apb_read(8'h04, read_value);

        if (read_value[2] == 1'b0) begin
            $display("PASS: RX valid cleared after DATA read");
        end
        else begin
            $display("FAIL: RX valid was not cleared");
            errors = errors + 1;
        end

        // --------------------------------------------
        // TEST 9: TX DONE STATUS
        // --------------------------------------------

        if (read_value[1] == 1'b1) begin
            $display("PASS: TX done status detected");
        end
        else begin
            $display("FAIL: TX done status missing");
            errors = errors + 1;
        end

        // --------------------------------------------
        // TEST 10: INVALID ADDRESS
        // --------------------------------------------

        @(negedge pclk);

        psel    = 1'b1;
        penable = 1'b0;
        pwrite  = 1'b0;
        paddr   = 8'h0C;

        @(negedge pclk);

        penable = 1'b1;

        #1;

        if (pslverr) begin
            $display("PASS: Invalid address detected");
        end
        else begin
            $display("FAIL: Invalid address not detected");
            errors = errors + 1;
        end

        @(negedge pclk);

        psel    = 1'b0;
        penable = 1'b0;

        // --------------------------------------------
        // FINAL RESULT
        // --------------------------------------------

        $display("");
        $display("====================================");

        if (errors == 0) begin
            $display("ALL UART LOOPBACK TESTS PASSED!");
        end
        else begin
            $display("UART LOOPBACK TESTS FAILED");
            $display("Total errors: %0d", errors);
        end

        $display("====================================");

        $finish;

    end

    // ------------------------------------------------
    // SIMULATION TIMEOUT
    // ------------------------------------------------

    initial begin

        #20_000_000;

        $display("ERROR: Simulation timeout!");
        $finish;

    end

endmodule
