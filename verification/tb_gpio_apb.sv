
`timescale 1ns/1ps

module tb_gpio_apb;

    // Parameters
    localparam int GPIO_WIDTH = 8;
    localparam int ADDR_WIDTH = 8;
    localparam int DATA_WIDTH = 32;

    // Clock and reset
    logic pclk;
    logic presetn;

    // APB signals
    logic                  psel;
    logic                  penable;
    logic                  pwrite;
    logic [ADDR_WIDTH-1:0] paddr;
    logic [DATA_WIDTH-1:0] pwdata;
    logic [DATA_WIDTH-1:0] prdata;
    logic                  pready;
    logic                  pslverr;

    // GPIO signals
    logic [GPIO_WIDTH-1:0] gpio_in;
    logic [GPIO_WIDTH-1:0] gpio_out;
    logic [GPIO_WIDTH-1:0] gpio_oe;

    // DUT instantiation
    gpio_apb #(
        .GPIO_WIDTH(GPIO_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .pclk     (pclk),
        .presetn  (presetn),
        .psel     (psel),
        .penable  (penable),
        .pwrite   (pwrite),
        .paddr    (paddr),
        .pwdata   (pwdata),
        .prdata   (prdata),
        .pready   (pready),
        .pslverr  (pslverr),
        .gpio_in  (gpio_in),
        .gpio_out (gpio_out),
        .gpio_oe  (gpio_oe)
    );

    // Clock generation: 10 ns period
    initial begin
        pclk = 1'b0;
        forever #5 pclk = ~pclk;
    end

    // VCD waveform generation
    initial begin
        $dumpfile("results/gpio_apb.vcd");
        $dumpvars(0, tb_gpio_apb);
    end

    // APB write task
    task automatic apb_write(
        input logic [ADDR_WIDTH-1:0] address,
        input logic [DATA_WIDTH-1:0] data,
        input logic expected_error
    );
        begin
            // Setup phase
            @(negedge pclk);
            psel   = 1'b1;
            penable = 1'b0;
            pwrite = 1'b1;
            paddr  = address;
            pwdata = data;

            // Access phase
            @(negedge pclk);
            penable = 1'b1;

            #1;
            if (pslverr !== expected_error) begin
                $fatal(1,
                    "WRITE ERROR MISMATCH: addr=%h expected=%b actual=%b",
                    address, expected_error, pslverr);
            end

            // Complete transfer
            @(negedge pclk);
            psel    = 1'b0;
            penable = 1'b0;
            pwrite  = 1'b0;

            $display("WRITE: addr=%h data=%h error=%b",
                     address, data, pslverr);
        end
    endtask

    // APB read task
    task automatic apb_read(
        input logic [ADDR_WIDTH-1:0] address,
        input logic [DATA_WIDTH-1:0] expected_data,
        input logic expected_error
    );
        begin
            // Setup phase
            @(negedge pclk);
            psel    = 1'b1;
            penable = 1'b0;
            pwrite  = 1'b0;
            paddr   = address;
            pwdata  = '0;

            // Access phase
            @(negedge pclk);
            penable = 1'b1;

            #1;
            if (pslverr !== expected_error) begin
                $fatal(1,
                    "READ ERROR MISMATCH: addr=%h expected=%b actual=%b",
                    address, expected_error, pslverr);
            end

            if (prdata !== expected_data) begin
                $fatal(1,
                    "READ DATA MISMATCH: addr=%h expected=%h actual=%h",
                    address, expected_data, prdata);
            end

            $display("READ : addr=%h data=%h error=%b",
                     address, prdata, pslverr);

            // Complete transfer
            @(negedge pclk);
            psel    = 1'b0;
            penable = 1'b0;
        end
    endtask

    // Main test sequence
    initial begin

        // Initialize signals
        presetn = 1'b0;
        psel    = 1'b0;
        penable = 1'b0;
        pwrite  = 1'b0;
        paddr   = '0;
        pwdata  = '0;
        gpio_in = '0;

        $display("-----------------------------------");
        $display("Starting GPIO APB Verification");
        $display("-----------------------------------");

        // Reset
        repeat (2) @(negedge pclk);
        presetn = 1'b1;
        @(negedge pclk);

        // Test 1: Check reset values
        if (gpio_oe !== 8'h00 || gpio_out !== 8'h00)
            $fatal(1, "RESET TEST FAILED");

        $display("TEST 1 PASSED: Reset");

        // Test 2: Write DIR register
        apb_write(8'h00, 32'h0000_000F, 1'b0);

        if (gpio_oe !== 8'h0F)
            $fatal(1, "DIR WRITE FAILED");

        // Test 3: Read DIR register
        apb_read(8'h00, 32'h0000_000F, 1'b0);
        $display("TEST 2 PASSED: DIR register");

        // Test 4: Write OUT register
        apb_write(8'h04, 32'h0000_0005, 1'b0);

        if (gpio_out !== 8'h05)
            $fatal(1, "OUT WRITE FAILED");

        // Test 5: Read OUT register
        apb_read(8'h04, 32'h0000_0005, 1'b0);
        $display("TEST 3 PASSED: OUT register");

        // Test 6: Read external GPIO input
        gpio_in = 8'hA5;
        apb_read(8'h08, 32'h0000_00A5, 1'b0);
        $display("TEST 4 PASSED: IN register");

        // Test 7: Attempt write to read-only IN register
        apb_write(8'h08, 32'h0000_00FF, 1'b1);
        $display("TEST 5 PASSED: Read-only register protection");

        // Test 8: Access invalid address
        apb_read(8'h0C, 32'h0000_0000, 1'b1);
        $display("TEST 6 PASSED: Invalid address detection");

        // Test 9: Non-zero upper write-data bits
        apb_write(8'h04, 32'h0000_0105, 1'b1);

        if (gpio_out !== 8'h05)
            $fatal(1, "INVALID WRITE CHANGED OUT REGISTER");

        $display("TEST 7 PASSED: Upper data-bit validation");

        // Test 10: Reset again and check registers clear
        @(negedge pclk);
        presetn = 1'b0;

        repeat (2) @(negedge pclk);

        if (gpio_oe !== 8'h00 || gpio_out !== 8'h00)
            $fatal(1, "SECOND RESET TEST FAILED");

        presetn = 1'b1;

        $display("TEST 8 PASSED: Register reset");

        $display("-----------------------------------");
        $display("ALL GPIO APB TESTS PASSED!");
        $display("-----------------------------------");

        #20;
        $finish;
    end

endmodule
