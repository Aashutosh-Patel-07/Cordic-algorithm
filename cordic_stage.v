// cordic_stage.v
// A single CORDIC pipeline stage
// Registers are inside this module (output is reg driven by always block)
// Top-level connects stages via wire arrays

module cordic_stage #(
    parameter WIDTH = 16,
    parameter STAGE = 0
)(
    input                       clk,
    input                       rst,
    input  signed [WIDTH:0]     x_in,
    input  signed [WIDTH:0]     y_in,
    input  signed [31:0]        z_in,
    input  signed [31:0]        atan_val,
    output reg signed [WIDTH:0] x_out,
    output reg signed [WIDTH:0] y_out,
    output reg signed [31:0]    z_out
);

    wire z_sign = z_in[31];

    wire signed [WIDTH:0] x_shr = x_in >>> STAGE;
    wire signed [WIDTH:0] y_shr = y_in >>> STAGE;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            x_out <= 0;
            y_out <= 0;
            z_out <= 0;
        end else begin
            if (z_sign) begin
                x_out <= x_in + y_shr;
                y_out <= y_in - x_shr;
                z_out <= z_in + atan_val;
            end else begin
                x_out <= x_in - y_shr;
                y_out <= y_in + x_shr;
                z_out <= z_in - atan_val;
            end
        end
    end

endmodule
