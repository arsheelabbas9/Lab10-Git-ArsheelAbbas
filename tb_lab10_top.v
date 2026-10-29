`timescale 1ns / 1ps
//==================================================================
// tb_lab10_top : self-checking testbench for Lab 10
//   SIM_FAST = 1 -> every countdown step lasts ~170 CPU cycles (17 us)
//   instead of 1 s, so the whole test runs in ~0.3 ms of simulated time.
//
//   Test 1 : sw = 0           -> FSM stays in INPUT_WAIT, LEDs = 0
//   Test 2 : sw = 5           -> LEDs 5,4,3,2,1,0 ; later switch changes ignored
//   Test 3 : reset (btnC) during countdown -> LEDs cleared immediately
//   Test 4 : second countdown after reset (FSM re-armed)
//   Test 5 : processor hardware reset (btnU) during countdown
//==================================================================
module tb_lab10_top;
    reg         clk  = 1'b0;
    reg         btnC = 1'b0;      // memory-mapped FSM reset button
    reg         btnU = 1'b0;      // processor hardware reset
    reg  [15:0] sw   = 16'd0;
    wire [15:0] led;

    lab10_top #(.SIM_FAST(1)) dut (
        .clk (clk),
        .btnC(btnC),
        .btnU(btnU),
        .sw  (sw),
        .led (led)
    );

    always #5 clk = ~clk;                       // 100 MHz board clock

    integer errors = 0;

    // print every change of the LEDs
    always @(led) $display("[%0t ns] LED = %0d (0x%h)", $time, led, led);

    // wait until the LEDs show 'expected' (timeout = 100000 board clocks)
    task wait_for_led;
        input [15:0] expected;
        integer n;
        begin
            n = 0;
            while ((led !== expected) && (n < 100000)) begin
                @(posedge clk);
                n = n + 1;
            end
            if (led !== expected) begin
                $display("**** FAIL : timeout waiting for LED = %0d (LED = %0d)", expected, led);
                errors = errors + 1;
            end
        end
    endtask

    task check_led;
        input [15:0] expected;
        input [511:0] msg;
        begin
            if (led !== expected) begin
                $display("**** FAIL : %0s  (expected %0d, got %0d)", msg, expected, led);
                errors = errors + 1;
            end else
                $display("     PASS : %0s", msg);
        end
    endtask

    // the value 9 must never appear in test 2 (switch input ignored during countdown)
    reg watch9 = 1'b0;
    always @(led) if (watch9 && led === 16'd9) begin
        $display("**** FAIL : switch change was not ignored during countdown");
        errors = errors + 1;
    end

    initial begin
        $display("=== Lab 10 FSM testbench ===");
        repeat (200) @(posedge clk);

        // ---------------- Test 1 ----------------
        $display("--- Test 1 : switches = 0 -> remain in INPUT_WAIT");
        repeat (2000) @(posedge clk);
        check_led(16'd0, "LEDs are 0 while switches are 0");

        // ---------------- Test 2 ----------------
        $display("--- Test 2 : switches = 5 -> countdown 5..0");
        sw = 16'd5;
        wait_for_led(16'd5);
        check_led(16'd5, "captured value shown on LEDs");
        watch9 = 1'b1;
        sw = 16'd9;                              // must be ignored
        wait_for_led(16'd4);
        wait_for_led(16'd3);
        sw = 16'd0;
        wait_for_led(16'd2);
        wait_for_led(16'd1);
        wait_for_led(16'd0);
        watch9 = 1'b0;
        repeat (3000) @(posedge clk);
        check_led(16'd0, "returned to INPUT_WAIT, LEDs = 0");

        // ---------------- Test 3 ----------------
        $display("--- Test 3 : reset button during countdown");
        sw = 16'd7;
        wait_for_led(16'd7);
        wait_for_led(16'd6);
        wait_for_led(16'd5);
        btnC = 1'b1;                             // press reset
        repeat (400) @(posedge clk);             // 40 CPU cycles >> sync + poll latency
        check_led(16'd0, "reset cleared LEDs immediately");
        sw   = 16'd0;
        btnC = 1'b0;                             // release reset
        repeat (10000) @(posedge clk);
        check_led(16'd0, "FSM idle after reset (no further counting)");

        // ---------------- Test 4 ----------------
        $display("--- Test 4 : FSM re-armed after reset");
        sw = 16'd3;
        wait_for_led(16'd3);
        sw = 16'd0;
        wait_for_led(16'd2);
        wait_for_led(16'd1);
        wait_for_led(16'd0);
        repeat (3000) @(posedge clk);
        check_led(16'd0, "second countdown finished, LEDs = 0");

        // ---------------- Test 5 ----------------
        $display("--- Test 5 : processor hardware reset (btnU)");
        sw = 16'd6;
        wait_for_led(16'd6);
        wait_for_led(16'd5);
        sw   = 16'd0;
        btnU = 1'b1;
        repeat (100) @(posedge clk);
        btnU = 1'b0;
        repeat (3000) @(posedge clk);
        check_led(16'd0, "processor restarted, FSM in INPUT_WAIT, LEDs = 0");

        if (errors == 0) $display("=== ALL TESTS PASSED ===");
        else             $display("=== %0d TEST(S) FAILED ===", errors);
        $finish;
    end
endmodule
