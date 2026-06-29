// expected_values.v
// Known sine and cosine values in Q1.15 fixed-point format
// (scaled by 2^15 = 32768, so cos(0) = 32768, sin(90) = 32768)
//
// CORDIC output is further scaled by An factor (~0.6073)
// So expected CORDIC output = true_value * 32768 * 0.6073
// An_scaled = round(32768 * 0.6073) = 19898
//
// All angles in Q2.30 fixed-point (full circle = 2^32)
// angle_fixed = round(degrees / 360 * 2^32)

// ------- Angle encodings -------
`define ANGLE_0    32'h00000000  //   0 degrees
`define ANGLE_30   32'h15555555  //  30 degrees
`define ANGLE_45   32'h20000000  //  45 degrees
`define ANGLE_60   32'h2AAAAAAB  //  60 degrees
`define ANGLE_90   32'h40000000  //  90 degrees
`define ANGLE_135  32'h60000000  // 135 degrees
`define ANGLE_180  32'h80000000  // 180 degrees (negative, handled by quadrant)
`define ANGLE_N45  32'hE0000000  // -45 degrees

// ------- CORDIC output expected values (An-scaled, 16-bit signed) -------
// Formula: expected = round(cos/sin(angle_rad) * An * 2^(WIDTH-1))
// An = 0.6073, WIDTH = 16 => scale = 0.6073 * 32768 = 19898

// cos values
`define EXP_COS_0    16'd19898   // cos(0)   = 1.000  * 19898 = 19898
`define EXP_COS_30   16'd17236   // cos(30)  = 0.866  * 19898 = 17232 (approx)
`define EXP_COS_45   16'd14076   // cos(45)  = 0.707  * 19898 = 14078 (approx)
`define EXP_COS_60   16'd9949    // cos(60)  = 0.500  * 19898 = 9949
`define EXP_COS_90   16'd0       // cos(90)  = 0.000  * 19898 = 0
`define EXP_COS_N45  16'd14076   // cos(-45) = cos(45)

// sin values
`define EXP_SIN_0    16'd0       // sin(0)   = 0.000  * 19898 = 0
`define EXP_SIN_30   16'd9949    // sin(30)  = 0.500  * 19898 = 9949
`define EXP_SIN_45   16'd14076   // sin(45)  = 0.707  * 19898 = 14078 (approx)
`define EXP_SIN_60   16'd17236   // sin(60)  = 0.866  * 19898 = 17232 (approx)
`define EXP_SIN_90   16'd19898   // sin(90)  = 1.000  * 19898 = 19898
`define EXP_SIN_N45  16'hC854    // sin(-45) = -0.707 * 19898 (negative, 2's complement)

// Tolerance: allow +/- TOLERANCE LSBs of error due to fixed-point rounding
`define TOLERANCE    16'd200
