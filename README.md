# CORDIC Sine/Cosine Processor — Verilog HDL

A fully pipelined hardware implementation of the **CORDIC (COordinate Rotation DIgital Computer)** algorithm in Verilog, computing sine and cosine simultaneously using only **shift and add operations** — no multipliers required.

Simulated using **Icarus Verilog** and verified with **GTKWave**.

---

## What is CORDIC?

CORDIC is an iterative algorithm that rotates a vector toward a target angle using only binary shifts and additions. After N iterations, the x and y components of the rotated vector converge to **cos(θ)** and **sin(θ)** respectively.

Each iteration:
```
x_next = x - d * (y >> i)
y_next = y + d * (x >> i)
z_next = z - d * atan(2^-i)
```
where `d = +1` if z ≥ 0, else `d = -1`

---

## Project Structure

```
cordic_project/
├── atan_table.v         # Arctangent lookup table (Q2.30 fixed-point)
├── cordic_stage.v       # Single pipeline stage module
├── cordic.v             # Top-level: quadrant correction + pipeline + valid signal
├── expected_values.v    # Fixed-point expected values for testbench verification
├── cordic_tb.v          # Testbench: 6 angle tests + reset + valid signal checks
├── generate_expected.py # Python: CORDIC simulation + fixed-point value generator
└── README.md
```

---

## Improvements Over Baseline

| Feature | Baseline (cebarnes/cordic) | This Project |
|---|---|---|
| Pipeline stage | Inline generate block | Separate `cordic_stage.v` module |
| Reset signal | ❌ None | ✅ Active-high synchronous reset |
| Valid signal | ❌ None | ✅ Asserts after STAGES cycles |
| Testbench angles | 1 angle (others commented out) | 6 angles with pass/fail checking |
| Output verification | `$monitor` only | Expected value comparison with tolerance |
| atan table | Inside main module | Separate `atan_table.v` module |
| Parameterizable | Partially | WIDTH and STAGES both parameterizable |
| Python verification | ❌ None | ✅ `generate_expected.py` cross-checks values |

---

## Fixed-Point Representation

- **Angle input**: Q2.30 format — full circle = 2³² counts
  - 0° = `32'h00000000`
  - 45° = `32'h20000000`
  - 90° = `32'h40000000`
- **x, y (output)**: 16-bit signed, scaled by CORDIC gain An ≈ 0.6073
  - Set `x_start = round(0.6073 × 2^15) = 19898` so output = true cos/sin × 2^15

---

## How to Run

### Simulate
```bash
iverilog -o cordic_sim cordic_tb.v cordic.v cordic_stage.v atan_table.v
vvp cordic_sim
```

### View Waveforms
```bash
gtkwave cordic_tb.vcd
```

### Generate Expected Values (Python)
```bash
python3 generate_expected.py
```

---

## Test Cases

| Test | Angle | Expected cos | Expected sin |
|---|---|---|---|
| Reset hold | — | 0 | 0 |
| Valid timing | 0° | asserts after 16 cycles | — |
| Angle 0° | 0° | 19898 | 0 |
| Angle 30° | 30° | 17236 | 9949 |
| Angle 45° | 45° | 14076 | 14076 |
| Angle 60° | 60° | 9949 | 17236 |
| Angle 90° | 90° | 0 | 19898 |
| Angle -45° | -45° | 14076 | -14076 |
| Mid-op reset | 45° | resets to 0 | resets to 0 |

Tolerance: ±200 LSBs (due to fixed-point rounding across 16 pipeline stages)

---

## Key Concepts Demonstrated

- **Pipelined RTL design** — 16 independent registered stages, one new result per clock
- **Fixed-point arithmetic** — Q2.30 angle format, signed arithmetic right shifts
- **Quadrant correction** — pre-rotation to keep angle in CORDIC convergence range [-π/2, π/2]
- **Valid signal** — shift register tracks pipeline latency, signals when output is trustworthy
- **Modular design** — separate modules for stage, LUT, and top-level
- **Parameterized design** — WIDTH and STAGES adjustable without changing logic

---

## Tools

- **Icarus Verilog** — simulation
- **GTKWave** — waveform analysis
- **Python 3** — golden reference and fixed-point value generation
