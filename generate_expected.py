#!/usr/bin/env python3
"""
generate_expected.py
--------------------
Generates fixed-point expected values for CORDIC sine/cosine verification.
Also simulates the CORDIC algorithm in Python to cross-check output.

Usage:
    python3 generate_expected.py

Output:
    - Prints expected cos/sin values for each test angle
    - Prints CORDIC Python simulation results
    - Shows error between Python CORDIC and true math values
"""

import math

# -------------------------------------------------------
# Parameters (match your Verilog)
# -------------------------------------------------------
WIDTH  = 16
STAGES = 16

# An = product of cos(atan(2^-i)) for i = 0..STAGES-1
# This is the CORDIC gain factor (~0.6073 for many stages)
An = 1.0
for i in range(STAGES):
    An *= math.cos(math.atan(2**(-i)))

An_scaled = round(An * (2**(WIDTH - 1)))  # fixed-point An
print(f"CORDIC gain An       = {An:.6f}")
print(f"An scaled (x_start)  = {An_scaled}  (use this as x_start in testbench)")
print(f"Scale factor (2^{WIDTH-1}) = {2**(WIDTH-1)}\n")

# -------------------------------------------------------
# Angle encoding: Q2.30 fixed-point (full circle = 2^32)
# -------------------------------------------------------
def deg_to_fixed(deg):
    return round(deg / 360 * (2**32)) & 0xFFFFFFFF

def fixed_to_deg(fixed):
    # treat as signed 32-bit
    if fixed >= 2**31:
        fixed -= 2**32
    return fixed / (2**32) * 360

# -------------------------------------------------------
# Python CORDIC simulation (rotation mode)
# -------------------------------------------------------
def cordic_sim(angle_deg, stages=STAGES, width=WIDTH):
    """Simulate CORDIC in Python, returns (cos, sin) as floats"""
    # precompute atan table
    atan_t = [math.atan(2**(-i)) for i in range(stages)]

    # angle in radians
    angle_rad = math.radians(angle_deg)

    # quadrant correction to bring into [-pi/2, pi/2]
    x = An  # start with An so output is cos/sin directly
    y = 0.0
    z = angle_rad

    if z > math.pi / 2:
        x, y, z = -y, x, z - math.pi / 2
    elif z < -math.pi / 2:
        x, y, z = y, -x, z + math.pi / 2

    # CORDIC iterations
    for i in range(stages):
        if z >= 0:
            x, y, z = x - y * 2**(-i), y + x * 2**(-i), z - atan_t[i]
        else:
            x, y, z = x + y * 2**(-i), y - x * 2**(-i), z + atan_t[i]

    return x, y  # these are cos(angle), sin(angle)

# -------------------------------------------------------
# Test angles
# -------------------------------------------------------
test_angles = [0, 30, 45, 60, 90, -45]

print(f"{'Angle':>6} | {'True cos':>10} | {'True sin':>10} | "
      f"{'CORDIC cos':>10} | {'CORDIC sin':>10} | "
      f"{'Exp cos (FP)':>12} | {'Exp sin (FP)':>12} | {'Error cos':>9} | {'Error sin':>9}")
print("-" * 110)

for deg in test_angles:
    true_cos = math.cos(math.radians(deg))
    true_sin = math.sin(math.radians(deg))

    cordic_cos, cordic_sin = cordic_sim(deg)

    # fixed-point expected values (what Verilog should output)
    exp_cos_fp = round(true_cos * An_scaled)
    exp_sin_fp = round(true_sin * An_scaled)

    # CORDIC output in fixed-point
    cordic_cos_fp = round(cordic_cos * (2**(WIDTH - 1)))
    cordic_sin_fp = round(cordic_sin * (2**(WIDTH - 1)))

    err_cos = abs(cordic_cos_fp - exp_cos_fp)
    err_sin = abs(cordic_sin_fp - exp_sin_fp)

    print(f"{deg:>6} | {true_cos:>10.4f} | {true_sin:>10.4f} | "
          f"{cordic_cos:>10.4f} | {cordic_sin:>10.4f} | "
          f"{exp_cos_fp:>12} | {exp_sin_fp:>12} | {err_cos:>9} | {err_sin:>9}")

# -------------------------------------------------------
# Print Verilog define lines for expected_values.v
# -------------------------------------------------------
print("\n\n--- Verilog defines (copy to expected_values.v if needed) ---")
angle_names = {0: "0", 30: "30", 45: "45", 60: "60", 90: "90", -45: "N45"}
for deg in test_angles:
    true_cos = math.cos(math.radians(deg))
    true_sin = math.sin(math.radians(deg))
    exp_cos_fp = round(true_cos * An_scaled)
    exp_sin_fp = round(true_sin * An_scaled)
    name = angle_names[deg]
    # handle negative as 16-bit 2's complement
    cos_hex = exp_cos_fp & 0xFFFF
    sin_hex = exp_sin_fp & 0xFFFF
    angle_hex = deg_to_fixed(deg)
    print(f"`define ANGLE_{name:<4}  32'h{angle_hex:08X}  // {deg:>4} degrees")
    print(f"`define EXP_COS_{name:<4} 16'h{cos_hex:04X}    // cos({deg}) * An * 2^{WIDTH-1} = {exp_cos_fp}")
    print(f"`define EXP_SIN_{name:<4} 16'h{sin_hex:04X}    // sin({deg}) * An * 2^{WIDTH-1} = {exp_sin_fp}")
    print()
