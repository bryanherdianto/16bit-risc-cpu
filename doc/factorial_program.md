# Factorial Algorithm (5! = 120) Implementation & Verification

## 1. Algorithm Overview

This document specifies the implementation and verification of the **Factorial Algorithm** ($5! = 120$) on the **16-Bit RISC CPU**.

### Architectural Constraints & Design Choices
1. **Multi-Cycle Datapath**: Each instruction executes across an 8-state FSM (`IDLE` $\rightarrow$ `FETCH` $\rightarrow$ `DECODE` $\rightarrow$ `READ_OPERAND` $\rightarrow$ `READ_ADDRESS` $\rightarrow$ `EXECUTE` $\rightarrow$ `WRITE` $\rightarrow$ `COMPLETE`), taking exactly 7 clock cycles per instruction.
2. **Straight-Line Unrolled Execution**: Because the CPU's ISA does not contain branch/jump instructions (`BEQ`, `JMP`), loop algorithms are structured as deterministic unrolled instruction sequences.
3. **8-Bit Register Width**: General-purpose registers are 8 bits wide ($0 \dots 255$).
   * $4! = 24$ (`0x18`)
   * $5! = 120$ (`0x78`)
   * $6! = 720$ (Overflows 8 bits; requires $720 > 255$).
   * Therefore, **$N = 5$ ($5! = 120$)** is the maximum full factorial computable within the native 8-bit datapath without overflow.

---

## 2. Register Allocation

| Register | Role | Initial Value | Final Value |
| :---: | :--- | :---: | :---: |
| **`R0`** | **Accumulator / Running Product** | `0x01` ($1$) | **`0x78` ($120$)** |
| **`R1`** | **Step Multiplier / Counter** | `0x02` ($2$) | **`0x05` ($5$)** |

---

## 3. Instruction Encoding & Assembly Breakdown

The 16-bit instruction format is divided as:
* `[15:12]` : Opcode (4 bits)
* `[11]` : Address Flag ($A$: `0` = Immediate, `1` = Register)
* `[10]` : Negative Flag ($N$: Two's complement writeback)
* `[9:6]` : Operand 1 ($R_{dest}$ address, 4 bits)
* `[5:0]` : Operand 2 (6-bit immediate or `[5:2]` $R_{src}$ address)

| Step | Assembly | Opcode | A | N | Dest (`Op1`) | Src/Imm (`Op2`) | Machine Code (Hex) | RTL Operation & Status |
| :---: | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **1** | `STOR R0, #1` | `1001` | `0` | `0` | `0000` | `000001` | `0x9001` | $R_0 \leftarrow 1$ (Init product) |
| **2** | `STOR R1, #2` | `1001` | `0` | `0` | `0001` | `000010` | `0x9042` | $R_1 \leftarrow 2$ (Init multiplier) |
| **3** | `MUL  R0, R1` | `0010` | `1` | `0` | `0000` | `000100` | `0x2804` | $R_0 \leftarrow R_0 \times R_1 = 1 \times 2 = \mathbf{2}$ |
| **4** | `ADD  R1, #1` | `0000` | `0` | `0` | `0001` | `000001` | `0x0041` | $R_1 \leftarrow R_1 + 1 = 2 + 1 = \mathbf{3}$ |
| **5** | `MUL  R0, R1` | `0010` | `1` | `0` | `0000` | `000100` | `0x2804` | $R_0 \leftarrow R_0 \times R_1 = 2 \times 3 = \mathbf{6}$ ($3!$) |
| **6** | `ADD  R1, #1` | `0000` | `0` | `0` | `0001` | `000001` | `0x0041` | $R_1 \leftarrow R_1 + 1 = 3 + 1 = \mathbf{4}$ |
| **7** | `MUL  R0, R1` | `0010` | `1` | `0` | `0000` | `000100` | `0x2804` | $R_0 \leftarrow R_0 \times R_1 = 6 \times 4 = \mathbf{24}$ ($4!$) |
| **8** | `ADD  R1, #1` | `0000` | `0` | `0` | `0001` | `000001` | `0x0041` | $R_1 \leftarrow R_1 + 1 = 4 + 1 = \mathbf{5}$ |
| **9** | `MUL  R0, R1` | `0010` | `1` | `0` | `0000` | `000100` | `0x2804` | $R_0 \leftarrow R_0 \times R_1 = 24 \times 5 = \mathbf{120}$ ($5!$) |

---

## 4. Multi-Cycle FSM Execution Trace

Each of the 9 instructions progresses through the CPU's controller states:

```
[FETCH] -> [DECODE] -> [READ_OPERAND] -> [READ_ADDRESS] -> [EXECUTE] -> [WRITE] -> [COMPLETE]
  (T0)       (T1)          (T2)             (T3)          (T4)       (T5)         (T6)
```

* **Total Clock Cycles**: $9 \text{ instructions} \times 7 \text{ cycles/instruction} = \mathbf{63 \text{ clock cycles}}$ (plus reset & complete latency).
* **Clock Frequency**: At 100 MHz ($T_{clk} = 10\text{ ns}$), execution finishes in $\approx 670\text{ ns}$.

---

## 5. How to Simulate & Capture Waveforms

### Automated Command Line
Run the simulation runner script:
```powershell
python sim/run_sim.py factorial_tb
```
Or run all tests:
```powershell
python sim/run_sim.py all
```

### ModelSim Waveform Inspection
1. Open ModelSim and load work library.
2. Add the following signals to the Wave window:
   * `/factorial_tb/cpu_clk`
   * `/factorial_tb/cpu_reset`
   * `/factorial_tb/instruction` (format as Hexadecimal)
   * `/factorial_tb/uut/state` (shows FSM state transitions)
   * `/factorial_tb/uut/alu_result1` (shows intermediate multiplication & addition values)
   * `/factorial_tb/uut/cpu_registerfile/reg_file(0)` (`R0`, final value `0x78` / `120`)
   * `/factorial_tb/uut/cpu_registerfile/reg_file(1)` (`R1`, final value `0x05` / `5`)
3. Run simulation (`run -all`).
4. Zoom to fit and take screenshot for project documentation.
