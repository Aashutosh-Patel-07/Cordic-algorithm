// cordic_tb.v
// Testbench for pipelined CORDIC processor
// Tests 6 angles with pass/fail verification against expected values
// Verifies reset behaviour and valid signal timing
//
// Run with: iverilog -o cordic_sim cordic_tb.v cordic.v cordic_stage.v atan_table.v
//           vvp cordic_sim
//           gtkwave cordic_tb.vcd

`include "cordic.v"
`include "expected_values.v"
`timescale 1ns/1ps

module cordic_tb;

    // -------------------------------------------------------
    // Parameters
    // -------------------------------------------------------
    localparam WIDTH  = 16;
    localparam STAGES = 16;
    // An scaling factor: x_start = round(0.6073 * 2^(WIDTH-1)) = 19898
    localparam signed [WIDTH-1:0] An = 19898;

    // -------------------------------------------------------
    // DUT signals
    // -------------------------------------------------------
    reg                      clk;
    reg                      rst;
    reg  signed [WIDTH-1:0]  x_start;
    reg  signed [WIDTH-1:0]  y_start;
    reg  signed [31:0]       angle;
    wire signed [WIDTH-1:0]  cosine;
    wire signed [WIDTH-1:0]  sine;
    wire                     valid;

    // -------------------------------------------------------
    // Instantiate DUT
    // -------------------------------------------------------
    cordic #(
        .WIDTH  (WIDTH),
        .STAGES (STAGES)
    ) dut (
        .clk     (clk),
        .rst     (rst),
        .x_start (x_start),
        .y_start (y_start),
        .angle   (angle),
        .cosine  (cosine),
        .sine    (sine),
        .valid   (valid)
    );

    // -------------------------------------------------------
    // Clock generation: 10ns period (100 MHz)
    // -------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // -------------------------------------------------------
    // VCD dump for GTKWave
    // -------------------------------------------------------
    initial begin
        $dumpfile("cordic_tb.vcd");
        $dumpvars(0, cordic_tb);
    end

    // -------------------------------------------------------
    // Test tracking
    // -------------------------------------------------------
    integer pass_count;
    integer fail_count;

    // -------------------------------------------------------
    // Task: check output within tolerance and print result
    // -------------------------------------------------------
    task check_output;
        input [127:0]           test_name; // label string
        input signed [WIDTH-1:0] exp_cos;
        input signed [WIDTH-1:0] exp_sin;
        
        reg signed [WIDTH:0] cos_err;
        reg signed [WIDTH:0] sin_err;
        reg                  cos_ok;
        reg                  sin_ok;
        begin
            // compute absolute error
            cos_err = cosine - exp_cos;
            sin_err = sine   - exp_sin;
            if (cos_err < 0) cos_err = -cos_err;
            if (sin_err < 0) sin_err = -sin_err;

            cos_ok = (cos_err <= `TOLERANCE);
            sin_ok = (sin_err <= `TOLERANCE);

            if (cos_ok && sin_ok) begin
                $display("  PASS | %s | cos=%d (exp=%d) | sin=%d (exp=%d)",
                         test_name, cosine, exp_cos, sine, exp_sin);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL | %s | cos=%d (exp=%d, err=%d) | sin=%d (exp=%d, err=%d)",
                         test_name, cosine, exp_cos, cos_err, sine, exp_sin, sin_err);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // -------------------------------------------------------
    // Task: apply input, wait STAGES cycles, then check
    // -------------------------------------------------------
    task run_test;
        input [127:0]            test_name;
        input signed [31:0]      test_angle;
        input signed [WIDTH-1:0] exp_cos;
        input signed [WIDTH-1:0] exp_sin;
        begin
            @(negedge clk);
            angle   = test_angle;
            x_start = An;
            y_start = 0;
            // wait for pipeline to flush (STAGES cycles)
            repeat (STAGES + 2) @(posedge clk);
            #1; // small delay to let outputs settle
            check_output(test_name, exp_cos, exp_sin);
        end
    endtask

    // -------------------------------------------------------
    // Main test sequence
    // -------------------------------------------------------
    initial begin
        pass_count = 0;
        fail_count = 0;

        // initialise inputs
        rst     = 1;
        angle   = 0;
        x_start = An;
        y_start = 0;

        // ---- Test 1: Reset behaviour ----
        $display("\n--- Test: Reset ---");
        repeat (4) @(posedge clk);
        if (cosine === 0 && sine === 0)
            $display("  PASS | Reset holds outputs at 0");
        else
            $display("  FAIL | Reset did not zero outputs (cos=%d, sin=%d)", cosine, sine);

        // Release reset
        @(negedge clk);
        rst = 0;
        $display("\n--- Starting angle tests (pipeline latency = %0d cycles) ---", STAGES);

        // ---- Test 2: Valid signal timing ----
        $display("\n--- Test: Valid Signal ---");
        angle   = `ANGLE_0;
        x_start = An;
        y_start = 0;
        begin : valid_check
            integer cycle_count;
            cycle_count = 0;
            while (!valid && cycle_count < STAGES + 5) begin
                @(posedge clk);
                cycle_count = cycle_count + 1;
            end
            if (valid)
                $display("  PASS | Valid asserted after %0d cycles (expected ~%0d)", cycle_count, STAGES);
            else
                $display("  FAIL | Valid never asserted within %0d cycles", STAGES + 5);
        end

        // ---- Test 3-8: Angle tests ----
        $display("\n--- Angle Tests ---");
        run_test("  0 degrees", `ANGLE_0,   `EXP_COS_0,   `EXP_SIN_0  );
        run_test(" 30 degrees", `ANGLE_30,  `EXP_COS_30,  `EXP_SIN_30 );
        run_test(" 45 degrees", `ANGLE_45,  `EXP_COS_45,  `EXP_SIN_45 );
        run_test(" 60 degrees", `ANGLE_60,  `EXP_COS_60,  `EXP_SIN_60 );
        run_test(" 90 degrees", `ANGLE_90,  `EXP_COS_90,  `EXP_SIN_90 );
        run_test("-45 degrees", `ANGLE_N45, `EXP_COS_N45, `EXP_SIN_N45);

        // ---- Test 9: Reset mid-operation ----
        $display("\n--- Test: Reset Mid-Operation ---");
        angle   = `ANGLE_45;
        x_start = An;
        y_start = 0;
        repeat (STAGES / 2) @(posedge clk); // halfway through pipeline
        rst = 1;
        repeat (3) @(posedge clk);
        if (cosine === 0 && sine === 0 && valid === 0)
            $display("  PASS | Mid-operation reset correctly zeroes outputs and valid");
        else
            $display("  FAIL | Mid-operation reset failed (cos=%d, sin=%d, valid=%b)",
                     cosine, sine, valid);
        rst = 0;

        // ---- Summary ----
        $display("\n=============================");
        $display("  RESULTS: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("=============================\n");

        $finish;
    end

    // -------------------------------------------------------
    // Timeout watchdog
    // -------------------------------------------------------
    initial begin
        #100000;
        $display("TIMEOUT: simulation exceeded limit");
        $finish;
    end

endmodule
