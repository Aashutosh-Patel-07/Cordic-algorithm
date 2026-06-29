// expected_values.v
// Expected sine and cosine values for CORDIC testbench verification
// x_start = 32767 (full scale 2^15 - 1)
// Output = true_value * 32767

`define ANGLE_0    32'h00000000
`define ANGLE_30   32'h15555555
`define ANGLE_45   32'h20000000
`define ANGLE_60   32'h2AAAAAAB
`define ANGLE_90   32'h40000000
`define ANGLE_N45  32'hE0000000

`define EXP_COS_0    16'd32767
`define EXP_COS_30   16'd28377
`define EXP_COS_45   16'd23170
`define EXP_COS_60   16'd16384
`define EXP_COS_90   16'd0
`define EXP_COS_N45  16'd23170

`define EXP_SIN_0    16'd0
`define EXP_SIN_30   16'd16383
`define EXP_SIN_45   16'd23170
`define EXP_SIN_60   16'd28377
`define EXP_SIN_90   16'd32767
`define EXP_SIN_N45  16'hA57E   // -23170 in 2's complement

`define TOLERANCE    16'd500
