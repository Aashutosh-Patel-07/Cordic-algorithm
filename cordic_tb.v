// cordic_tb.v
`include "cordic.v"
`include "expected_values.v"
`timescale 1ns/1ps

module cordic_tb;

    localparam WIDTH  = 16;
    localparam STAGES = 16;
    localparam signed [WIDTH-1:0] An = 32767;

    reg                      clk;
    reg                      rst;
    reg  signed [WIDTH-1:0]  x_start;
    reg  signed [WIDTH-1:0]  y_start;
    reg  signed [31:0]       angle;
    wire signed [WIDTH-1:0]  cosine;
    wire signed [WIDTH-1:0]  sine;
    wire                     valid;

    cordic #(.WIDTH(WIDTH), .STAGES(STAGES)) dut (
        .clk(clk), .rst(rst),
        .x_start(x_start), .y_start(y_start),
        .angle(angle),
        .cosine(cosine), .sine(sine), .valid(valid)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("cordic_tb.vcd");
        $dumpvars(0, cordic_tb);
    end

    integer pass_count, fail_count;

    task check_output;
        input [127:0]            test_name;
        input signed [WIDTH-1:0] exp_cos;
        input signed [WIDTH-1:0] exp_sin;
        reg signed [WIDTH:0] cos_err, sin_err;
        reg cos_ok, sin_ok;
        begin
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
            repeat (STAGES + 4) @(posedge clk);
            #1;
            check_output(test_name, exp_cos, exp_sin);
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        rst     = 1;
        angle   = 0;
        x_start = An;
        y_start = 0;

        $display("\n--- Test: Reset ---");
        repeat (4) @(posedge clk);
        if (cosine === 0 && sine === 0)
            $display("  PASS | Reset holds outputs at 0");
        else
            $display("  FAIL | Reset did not zero outputs (cos=%d, sin=%d)", cosine, sine);

        @(negedge clk);
        rst = 0;

        $display("\n--- Test: Valid Signal ---");
        angle   = `ANGLE_0;
        x_start = An;
        y_start = 0;
        begin : valid_check
            integer cycle_count;
            cycle_count = 0;
            while (!valid && cycle_count < STAGES + 10) begin
                @(posedge clk);
                cycle_count = cycle_count + 1;
            end
            if (valid)
                $display("  PASS | Valid asserted after %0d cycles (expected ~%0d)", cycle_count, STAGES);
            else
                $display("  FAIL | Valid never asserted");
        end

        $display("\n--- Angle Tests ---");
        run_test("  0 degrees", `ANGLE_0,   `EXP_COS_0,   `EXP_SIN_0  );
        run_test(" 30 degrees", `ANGLE_30,  `EXP_COS_30,  `EXP_SIN_30 );
        run_test(" 45 degrees", `ANGLE_45,  `EXP_COS_45,  `EXP_SIN_45 );
        run_test(" 60 degrees", `ANGLE_60,  `EXP_COS_60,  `EXP_SIN_60 );
        run_test(" 90 degrees", `ANGLE_90,  `EXP_COS_90,  `EXP_SIN_90 );
        run_test("-45 degrees", `ANGLE_N45, `EXP_COS_N45, `EXP_SIN_N45);

        $display("\n--- Test: Reset Mid-Operation ---");
        angle   = `ANGLE_45;
        x_start = An;
        y_start = 0;
        repeat (STAGES / 2) @(posedge clk);
        rst = 1;
        repeat (3) @(posedge clk);
        if (cosine === 0 && sine === 0 && valid === 0)
            $display("  PASS | Mid-operation reset correctly zeroes outputs and valid");
        else
            $display("  FAIL | Mid-operation reset failed (cos=%d, sin=%d, valid=%b)", cosine, sine, valid);
        rst = 0;

        $display("\n=============================");
        $display("  RESULTS: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("=============================\n");
        $finish;
    end

    initial begin
        #100000;
        $display("TIMEOUT");
        $finish;
    end

endmodule
