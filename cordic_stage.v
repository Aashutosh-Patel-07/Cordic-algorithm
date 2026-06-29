// cordic_stage.v
// A single CORDIC pipeline stage
// Each stage performs one vector rotation iteration
//
// Operation:
//   If z >= 0 (z_sign = 0): rotate counter-clockwise
//       x_next = x - (y >> i)
//       y_next = y + (x >> i)
//       z_next = z - atan(2^-i)
//   If z < 0  (z_sign = 1): rotate clockwise
//       x_next = x + (y >> i)
//       y_next = y - (x >> i)
//       z_next = z + atan(2^-i)

module cordic_stage #(
    parameter WIDTH = 16,   // bit width of x and y
    parameter STAGE = 0     // stage index (shift amount)
)(
    input                        clk,
    input                        rst,
    // inputs from previous stage
    input  signed [WIDTH:0]      x_in,
    input  signed [WIDTH:0]      y_in,
    input  signed [31:0]         z_in,
    // atan value for this stage from lookup table
    input  signed [31:0]         atan_val,
    // outputs to next stage
    output reg signed [WIDTH:0]  x_out,
    output reg signed [WIDTH:0]  y_out,
    output reg signed [31:0]     z_out
);

    // sign of z determines rotation direction
    wire z_sign = z_in[31];

    // arithmetic right shift by STAGE positions
    wire signed [WIDTH:0] x_shr = x_in >>> STAGE;
    wire signed [WIDTH:0] y_shr = y_in >>> STAGE;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            x_out <= 0;
            y_out <= 0;
            z_out <= 0;
        end else begin
            if (z_sign) begin
                // z is negative: rotate clockwise to increase z toward 0
                x_out <= x_in + y_shr;
                y_out <= y_in - x_shr;
                z_out <= z_in + atan_val;
            end else begin
                // z is positive: rotate counter-clockwise to reduce z toward 0
                x_out <= x_in - y_shr;
                y_out <= y_in + x_shr;
                z_out <= z_in - atan_val;
            end
        end
    end

endmodule
