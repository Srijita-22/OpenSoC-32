
`timescale 1ns/1ps

module tb_uart_apb;

    localparam CLK_FREQ_HZ = 50_000_000;
    localparam BAUD_RATE   = 9600;
    localparam BAUD_DIV    = CLK_FREQ_HZ / BAUD_RATE;

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

    logic uart_tx;

    integer errors;
    integer i;

    logic [7:0] test_data;

    // DUT
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

        .uart_tx(uart_tx)
    );

    // 50 MHz clock: 20 ns period
    initial begin
        pclk = 0;
        forever #10 pclk = ~pclk;
    end

    // APB write task
    task automatic apb_write(
        input logic [7:0] addr,
        input logic [31:0] data
    );
        begin
            @(negedge pclk);
            psel   = 1;
            penable = 0;
            pwrite = 1;
            paddr  = addr;
            pwdata = data;

            @(negedge pclk);
            penable = 1;

            @(negedge pclk);
            psel   = 0;
            penable = 0;
            pwrite = 0;
        end
    endtask

    // APB read task
    task automatic apb_read(
        input logic [7:0] addr,
        output logic [31:0] data
    );
        begin
            @(negedge pclk);
            psel   = 1;
            penable = 0;
            pwrite = 0;
            paddr  = addr;

            @(negedge pclk);
            penable = 1;

            #1;
            data = prdata;

            @(negedge pclk);
            psel   = 0;
            penable = 0;
        end
    endtask

    // Main test
    initial begin

        $dumpfile("results/uart_apb.vcd");
        $dumpvars(0, tb_uart_apb);

        errors = 0;

        pclk = 0;
        presetn = 0;

        psel = 0;
        penable = 0;
        pwrite = 0;
        paddr = 0;
        pwdata = 0;

        test_data = 8'hA5;

        $display("--------------------------------");
        $display(" UART APB TRANSMITTER TEST");
        $display("--------------------------------");

        // TEST 1: Reset
        repeat (5) @(negedge pclk);
        presetn = 1;
        @(negedge pclk);

        if (uart_tx !== 1'b1) begin
            $display("FAIL: TX idle should be HIGH");
            errors = errors + 1;
        end
        else
            $display("PASS: Reset and TX idle");

        // TEST 2: Baud divider
        begin
            logic [31:0] read_value;

            apb_read(8'h08, read_value);

            if (read_value == BAUD_DIV)
                $display("PASS: Default baud divider = %0d",
                         read_value);
            else begin
                $display("FAIL: Baud divider = %0d",
                         read_value);
                errors = errors + 1;
            end
        end

        // TEST 3: Transmit byte A5
        apb_write(8'h00, {24'd0, test_data});

        // Check start bit
        @(negedge pclk);

        if (uart_tx !== 1'b0) begin
            $display("FAIL: Start bit should be LOW");
            errors = errors + 1;
        end
        else
            $display("PASS: Start bit detected");

        // Wait until middle of each data bit
        // Start bit has already begun.
        repeat (BAUD_DIV + (BAUD_DIV/2)) @(posedge pclk);

        for (i = 0; i < 8; i = i + 1) begin

            if (uart_tx !== test_data[i]) begin
                $display("FAIL: Data bit %0d expected %0b got %0b",
                         i, test_data[i], uart_tx);
                errors = errors + 1;
            end
            else
                $display("PASS: Data bit %0d = %0b",
                         i, uart_tx);

            repeat (BAUD_DIV) @(posedge pclk);

        end

        // Check stop bit
        if (uart_tx !== 1'b1) begin
            $display("FAIL: Stop bit should be HIGH");
            errors = errors + 1;
        end
        else
            $display("PASS: Stop bit");

        // Wait for transmission completion
        wait (dut.tx_done == 1'b1);
        @(negedge pclk);

        // TEST 4: Status register
        begin
            logic [31:0] status_value;

            apb_read(8'h04, status_value);

            if (status_value[0] == 1'b0 &&
                status_value[1] == 1'b1)
                $display("PASS: TX status completed");
            else begin
                $display("FAIL: Incorrect TX status");
                errors = errors + 1;
            end
        end

        // TEST 5: Invalid address
        @(negedge pclk);
        psel = 1;
        penable = 0;
        pwrite = 0;
        paddr = 8'h0C;

        @(negedge pclk);
        penable = 1;
        #1;

        if (pslverr)
            $display("PASS: Invalid address error detected");
        else begin
            $display("FAIL: Invalid address error missing");
            errors = errors + 1;
        end

        @(negedge pclk);
        psel = 0;
        penable = 0;

        // Final result
        $display("--------------------------------");

        if (errors == 0)
            $display("ALL UART APB TESTS PASSED!");
        else
            $display("UART APB TESTS FAILED: %0d errors", errors);

        $display("--------------------------------");

        $finish;
    end

    // Simulation timeout
    initial begin
        #20_000_000;
        $display("ERROR: Simulation timeout");
        $finish;
    end

endmodule
