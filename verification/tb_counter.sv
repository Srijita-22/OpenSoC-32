
`timescale 1ns/1ps

module tb_counter;

    logic clk;
    logic rst_n;
    logic en;
    logic [7:0] count;

    counter #(
        .WIDTH(8)
    ) dut (
        .clk   (clk),
        .rst_n (rst_n),
        .en    (en),
        .count (count)
    );

    // 10 ns clock period
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("results/counter.vcd");
        $dumpvars(0, tb_counter);

        // Initialize
        rst_n = 0;
        en    = 0;

        #12;
        rst_n = 1;
        en    = 1;

        // Count from 0 to 5
        repeat (5) @(posedge clk);
        #1;

        if (count !== 8'd5)
            $fatal(1, "FAIL: Expected 5, got %0d", count);

        $display("PASS: Counter reached %0d", count);

        // Disable counter
        en = 0;
        repeat (3) @(posedge clk);
        #1;

        if (count !== 8'd5)
            $fatal(1, "FAIL: Counter changed while disabled");

        $display("PASS: Counter held at %0d", count);

        // Test reset
        rst_n = 0;
        #1;

        if (count !== 8'd0)
            $fatal(1, "FAIL: Reset did not clear counter");

        $display("PASS: Reset cleared counter");

        $display("ALL TESTS PASSED");
        $finish;
    end

endmodule
