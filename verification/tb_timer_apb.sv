
`timescale 1ns/1ps

module tb_timer_apb;

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
    logic timer_irq;

    // DUT
    timer_apb dut (
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
        .timer_irq(timer_irq)
    );

    // 50 MHz clock
    initial begin
        pclk = 1'b0;
        forever #10 pclk = ~pclk;
    end

    // APB write task
    task automatic apb_write(
        input logic [7:0] address,
        input logic [31:0] data
    );
        begin
            @(negedge pclk);
            psel    = 1'b1;
            penable = 1'b0;
            pwrite  = 1'b1;
            paddr   = address;
            pwdata  = data;

            @(negedge pclk);
            penable = 1'b1;

            @(negedge pclk);
            psel    = 1'b0;
            penable = 1'b0;
            pwrite  = 1'b0;
        end
    endtask

    // APB read task
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
        end
    endtask

    logic [31:0] read_data;

    initial begin
        $dumpfile("results/timer_apb.vcd");
        $dumpvars(0, tb_timer_apb);
    end

    initial begin

        // Initialize APB
        presetn = 1'b0;
        psel    = 1'b0;
        penable = 1'b0;
        pwrite  = 1'b0;
        paddr   = 8'h00;
        pwdata  = 32'b0;

        repeat (3) @(negedge pclk);
        presetn = 1'b1;

        $display("----------------------------------");
        $display("Starting APB Timer Tests");
        $display("----------------------------------");

        // TEST 1: Reset
        apb_read(8'h00, read_data);

        if (read_data !== 32'b0)
            $fatal(1, "RESET CONTROL REGISTER FAILED");

        apb_read(8'h04, read_data);

        if (read_data !== 32'b0)
            $fatal(1, "RESET LOAD REGISTER FAILED");

        $display("TEST 1 PASSED: Reset");

        // TEST 2: Load register write/read
        apb_write(8'h04, 32'd100);
        apb_read(8'h04, read_data);

        if (read_data !== 32'd100)
            $fatal(1, "LOAD REGISTER FAILED");

        $display("TEST 2 PASSED: Load register");

        // TEST 3: Counter load
        apb_read(8'h08, read_data);

        if (read_data !== 32'd100)
            $fatal(1, "COUNTER LOAD FAILED");

        $display("TEST 3 PASSED: Counter load");

        // TEST 4: Timer enable
        apb_write(8'h00, 32'd1);

        if (dut.ctrl_reg[0] !== 1'b1)
            $fatal(1, "TIMER ENABLE FAILED");

        $display("TEST 4 PASSED: Timer enable");

        // TEST 5: Countdown
        repeat (5) @(negedge pclk);
        apb_read(8'h08, read_data);

        if (read_data >= 32'd100 || read_data == 32'd0)
            $fatal(1, "COUNTDOWN FAILED: VALUE=%0d", read_data);

        $display("TEST 5 PASSED: Countdown");

        // TEST 6: Disable timer
        apb_write(8'h00, 32'd0);
        apb_read(8'h08, read_data);

        begin : disable_check
            logic [31:0] saved_value;
            saved_value = read_data;
            repeat (5) @(negedge pclk);
            apb_read(8'h08, read_data);

            if (read_data !== saved_value)
                $fatal(1, "TIMER DID NOT STOP");
        end

        $display("TEST 6 PASSED: Timer disable");

        // TEST 7: Configure short timer
        apb_write(8'h04, 32'd3);
        apb_write(8'h00, 32'd3);

        // Wait for expiry
        wait (timer_irq === 1'b1);
        #1;

        if (dut.irq_pending !== 1'b1)
            $fatal(1, "INTERRUPT PENDING NOT SET");

        $display("TEST 7 PASSED: Timer interrupt generation");

        // TEST 8: Interrupt pending read
        apb_read(8'h0C, read_data);

        if (read_data[0] !== 1'b1)
            $fatal(1, "INTERRUPT STATUS READ FAILED");

        $display("TEST 8 PASSED: Interrupt pending status");

        // TEST 9: Interrupt clear
        apb_write(8'h00, 32'd0);
        apb_write(8'h0C, 32'd1);

        apb_read(8'h0C, read_data);

        if (read_data[0] !== 1'b0)
            $fatal(1, "INTERRUPT CLEAR FAILED");

        $display("TEST 9 PASSED: Interrupt clear");

        // TEST 10: Invalid address
        @(negedge pclk);
        psel    = 1'b1;
        penable = 1'b0;
        pwrite  = 1'b0;
        paddr   = 8'h10;

        @(negedge pclk);
        penable = 1'b1;
        #1;

        if (pslverr !== 1'b1)
            $fatal(1, "INVALID ADDRESS ERROR FAILED");

        @(negedge pclk);
        psel    = 1'b0;
        penable = 1'b0;

        $display("TEST 10 PASSED: Invalid address");

        // TEST 11: Write protection
        @(negedge pclk);
        psel    = 1'b1;
        penable = 1'b0;
        pwrite  = 1'b1;
        paddr   = 8'h08;
        pwdata  = 32'd50;

        @(negedge pclk);
        penable = 1'b1;
        #1;

        if (pslverr !== 1'b1)
            $fatal(1, "VALUE REGISTER WRITE PROTECTION FAILED");

        @(negedge pclk);
        psel    = 1'b0;
        penable = 1'b0;
        pwrite  = 1'b0;

        $display("TEST 11 PASSED: Write protection");

        $display("----------------------------------");
        $display("ALL APB TIMER TESTS PASSED!");
        $display("----------------------------------");

        #20;
        $finish;
    end

    // Simulation timeout
    initial begin
        #100000;
        $fatal(1, "TIMER TESTBENCH TIMEOUT");
    end

endmodule
