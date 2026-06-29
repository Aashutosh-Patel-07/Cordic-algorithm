// atan_table.v
// Arctangent lookup table for CORDIC algorithm
// atan_table[i] = atan(2^-i) in Q2.30 fixed-point format
// Q2.30 means: 2 integer bits, 30 fractional bits
// Full circle = 2^32, so 90 degrees = 2^30

module atan_table #(parameter STAGES = 16)(
    input  [$clog2(STAGES)-1:0] index,
    output reg signed [31:0]    atan_val
);

always @(*) begin
    case(index)
        5'd00: atan_val = 32'h20000000; // atan(2^0)  = 45.000 deg
        5'd01: atan_val = 32'h12E4051E; // atan(2^-1) = 26.565 deg
        5'd02: atan_val = 32'h09FB385B; // atan(2^-2) = 14.036 deg
        5'd03: atan_val = 32'h05111D14; // atan(2^-3) =  7.125 deg
        5'd04: atan_val = 32'h028B0D43; // atan(2^-4) =  3.576 deg
        5'd05: atan_val = 32'h0145D7E1; // atan(2^-5) =  1.789 deg
        5'd06: atan_val = 32'h00A2F61E; // atan(2^-6) =  0.895 deg
        5'd07: atan_val = 32'h00517C55; // atan(2^-7) =  0.448 deg
        5'd08: atan_val = 32'h0028BE53; // atan(2^-8) =  0.224 deg
        5'd09: atan_val = 32'h00145F2E; // atan(2^-9) =  0.112 deg
        5'd10: atan_val = 32'h000A2F98; // atan(2^-10)=  0.056 deg
        5'd11: atan_val = 32'h000517CC; // atan(2^-11)=  0.028 deg
        5'd12: atan_val = 32'h00028BE6; // atan(2^-12)=  0.014 deg
        5'd13: atan_val = 32'h000145F3; // atan(2^-13)=  0.007 deg
        5'd14: atan_val = 32'h0000A2F9; // atan(2^-14)=  0.003 deg
        5'd15: atan_val = 32'h0000517C; // atan(2^-15)=  0.002 deg
        default: atan_val = 32'h00000000;
    endcase
end

endmodule
