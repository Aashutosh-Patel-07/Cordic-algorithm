// expected_values.v
// Expected CORDIC outputs with x_start=16384, output read as [WIDTH:1]
// Scale factor: cos(0) = 13491, sin(90) = 13492 (hardware verified)
// Ratios: cos(45)/cos(0) = 9540/13491 = 0.7071 = cos(45 deg) -- correct!

`define ANGLE_0    32'h00000000
`define ANGLE_30   32'h15555555
`define ANGLE_45   32'h20000000
`define ANGLE_60   32'h2AAAAAAB
`define ANGLE_90   32'h40000000
`define ANGLE_N45  32'hE0000000

`define EXP_COS_0    16'd13491
`define EXP_COS_30   16'd11684
`define EXP_COS_45   16'd9540
`define EXP_COS_60   16'd6746
`define EXP_COS_90   16'd0
`define EXP_COS_N45  16'd9540

`define EXP_SIN_0    16'd0
`define EXP_SIN_30   16'd6745
`define EXP_SIN_45   16'd9540
`define EXP_SIN_60   16'd11684
`define EXP_SIN_90   16'd13491
`define EXP_SIN_N45  16'hDABC   // -9540 in 2's complement

`define TOLERANCE    16'd50
