// cordic.v
// Top-level pipelined CORDIC processor
// Computes sine and cosine simultaneously using iterative vector rotation
//
// Key improvements over baseline:
//   1. Separate cordic_stage.v module per stage (modular, readable)
//   2. Separate atan_table.v lookup module
//   3. Reset signal added
//   4. Valid signal output — goes high after STAGES pipeline cycles
//   5. Parameterizable WIDTH and STAGES
//
// Fixed-point format: Q2.30 for angle (full circle = 2^32)
// Input angle range: full 360 degrees (quadrant correction handles all 4)
// Latency: STAGES clock cycles after valid input

`include "atan_table.v"
`include "cordic_stage.v"

module cordic #(
    parameter WIDTH  = 16,
    parameter STAGES = 16
)(
    input                        clk,
    input                        rst,
    input  signed [WIDTH-1:0]    x_start,
    input  signed [WIDTH-1:0]    y_start,
    input  signed [31:0]         angle,
    output signed [WIDTH-1:0]    cosine,
    output signed [WIDTH-1:0]    sine,
    output                       valid
);

    // -------------------------------------------------------
    // Wire arrays for inter-stage connections
    // wire[0] = stage 0 input, wire[i+1] = output of stage i
    // cordic_stage registers internally, so outputs are wires here
    // -------------------------------------------------------
    wire signed [WIDTH:0] x_wire [0:STAGES];
    wire signed [WIDTH:0] y_wire [0:STAGES];
    wire signed [31:0]    z_wire [0:STAGES];

    // -------------------------------------------------------
    // Stage 0 input: quadrant correction (registered)
    // -------------------------------------------------------
    reg signed [WIDTH:0] x0_reg;
    reg signed [WIDTH:0] y0_reg;
    reg signed [31:0]    z0_reg;

    wire [1:0] quadrant = angle[31:30];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            x0_reg <= 0;
            y0_reg <= 0;
            z0_reg <= 0;
        end else begin
            case (quadrant)
                2'b00, 2'b11: begin
                    x0_reg <= x_start;
                    y0_reg <= y_start;
                    z0_reg <= angle;
                end
                2'b01: begin
                    x0_reg <= -y_start;
                    y0_reg <=  x_start;
                    z0_reg <= {2'b00, angle[29:0]};
                end
                2'b10: begin
                    x0_reg <=  y_start;
                    y0_reg <= -x_start;
                    z0_reg <= {2'b11, angle[29:0]};
                end
            endcase
        end
    end

    // Connect reg to wire[0]
    assign x_wire[0] = x0_reg;
    assign y_wire[0] = y0_reg;
    assign z_wire[0] = z0_reg;

    // -------------------------------------------------------
    // Atan lookup table instantiation
    // -------------------------------------------------------
    wire signed [31:0] atan_vals [0:STAGES-1];

    genvar k;
    generate
        for (k = 0; k < STAGES; k = k + 1) begin : atan_lut
            atan_table #(.STAGES(STAGES)) lut_inst (
                .index    (k[$clog2(STAGES)-1:0]),
                .atan_val (atan_vals[k])
            );
        end
    endgenerate

    // -------------------------------------------------------
    // Pipeline stage instantiation
    // Each stage reads from wire[i], writes to wire[i+1]
    // -------------------------------------------------------
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : pipeline
            cordic_stage #(
                .WIDTH (WIDTH),
                .STAGE (i)
            ) stage_inst (
                .clk      (clk),
                .rst      (rst),
                .x_in     (x_wire[i]),
                .y_in     (y_wire[i]),
                .z_in     (z_wire[i]),
                .atan_val (atan_vals[i]),
                .x_out    (x_wire[i+1]),
                .y_out    (y_wire[i+1]),
                .z_out    (z_wire[i+1])
            );
        end
    endgenerate

    // -------------------------------------------------------
    // Valid signal: shift register, asserts after STAGES+1 cycles
    // -------------------------------------------------------
    reg [STAGES:0] valid_shift;

    always @(posedge clk or posedge rst) begin
        if (rst)
            valid_shift <= 0;
        else
            valid_shift <= {valid_shift[STAGES-1:0], 1'b1};
    end

    assign valid  = valid_shift[STAGES];
    assign cosine = x_wire[STAGES][WIDTH-1:0];
    assign sine   = y_wire[STAGES][WIDTH-1:0];

endmodule
