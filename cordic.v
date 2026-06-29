// cordic.v
// Top-level pipelined CORDIC processor
// Computes sine and cosine simultaneously using iterative vector rotation
//
// Key improvements over baseline:
//   1. Separate cordic_stage.v module per stage (modular, readable)
//   2. Separate atan_table.v lookup module
//   3. Reset signal added
//   4. Valid signal output — goes high after WIDTH-1 pipeline cycles
//   5. Parameterizable WIDTH and STAGES
//
// Fixed-point format: Q2.30 for angle (full circle = 2^32)
// Output scaling: cosine and sine scaled by An = product of cos(atan(2^-i))
//                 To get true values, multiply output by 1/An ~ 1.647
//
// Input angle range: full 360 degrees (quadrant correction handles all 4)
// Latency: STAGES clock cycles after valid input

`include "atan_table.v"
`include "cordic_stage.v"

module cordic #(
    parameter WIDTH  = 16,  // bit width of x, y outputs
    parameter STAGES = 16   // number of pipeline stages = iterations
)(
    input                        clk,
    input                        rst,
    input  signed [WIDTH-1:0]    x_start,   // initial x (set to An scaled value)
    input  signed [WIDTH-1:0]    y_start,   // initial y (usually 0)
    input  signed [31:0]         angle,     // input angle in Q2.30 format
    output signed [WIDTH-1:0]    cosine,    // cosine output
    output signed [WIDTH-1:0]    sine,      // sine output
    output                       valid      // high when output is valid
);

    // -------------------------------------------------------
    // Quadrant correction
    // CORDIC only converges for angles in [-pi/2, pi/2]
    // Use top 2 bits of angle to detect quadrant
    // and pre-rotate x,y into the valid range
    // -------------------------------------------------------
    wire [1:0] quadrant = angle[31:30];

    reg signed [WIDTH:0] x_stage [0:STAGES-1];
    reg signed [WIDTH:0] y_stage [0:STAGES-1];
    reg signed [31:0]    z_stage [0:STAGES-1];

    // Quadrant correction at stage 0 input (registered)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            x_stage[0] <= 0;
            y_stage[0] <= 0;
            z_stage[0] <= 0;
        end else begin
            case (quadrant)
                2'b00, 2'b11: begin
                    // Quadrants 1 and 4: already in range
                    x_stage[0] <= x_start;
                    y_stage[0] <= y_start;
                    z_stage[0] <= angle;
                end
                2'b01: begin
                    // Quadrant 2: rotate by -90 degrees
                    x_stage[0] <= -y_start;
                    y_stage[0] <=  x_start;
                    z_stage[0] <= {2'b00, angle[29:0]}; // angle - pi/2
                end
                2'b10: begin
                    // Quadrant 3: rotate by +90 degrees
                    x_stage[0] <=  y_start;
                    y_stage[0] <= -x_start;
                    z_stage[0] <= {2'b11, angle[29:0]}; // angle + pi/2
                end
            endcase
        end
    end

    // -------------------------------------------------------
    // Instantiate STAGES pipeline stages using generate
    // Each stage is a separate cordic_stage module
    // -------------------------------------------------------
    wire signed [31:0] atan_vals [0:STAGES-1];

    genvar k;
    generate
        for (k = 0; k < STAGES; k = k + 1) begin : atan_lut
            atan_table #(.STAGES(STAGES)) lut_inst (
                .index  (k[$clog2(STAGES)-1:0]),
                .atan_val (atan_vals[k])
            );
        end
    endgenerate

    genvar i;
    generate
        for (i = 0; i < STAGES - 1; i = i + 1) begin : pipeline
            cordic_stage #(
                .WIDTH (WIDTH),
                .STAGE (i)
            ) stage_inst (
                .clk      (clk),
                .rst      (rst),
                .x_in     (x_stage[i]),
                .y_in     (y_stage[i]),
                .z_in     (z_stage[i]),
                .atan_val (atan_vals[i]),
                .x_out    (x_stage[i+1]),
                .y_out    (y_stage[i+1]),
                .z_out    (z_stage[i+1])
            );
        end
    endgenerate

    // -------------------------------------------------------
    // Valid signal
    // Output becomes valid after STAGES clock cycles
    // Implemented as a shift register of width STAGES
    // -------------------------------------------------------
    reg [STAGES-1:0] valid_shift;

    always @(posedge clk or posedge rst) begin
        if (rst)
            valid_shift <= 0;
        else
            valid_shift <= {valid_shift[STAGES-2:0], 1'b1};
    end

    assign valid  = valid_shift[STAGES-1];

    // Final output — take upper WIDTH bits from last stage
    assign cosine = x_stage[STAGES-1][WIDTH-1:0];
    assign sine   = y_stage[STAGES-1][WIDTH-1:0];

endmodule
