# 16-Bit RISC CPU in VHDL

A modular, synthesizable **16-Bit RISC CPU** implemented in VHDL, featuring an 8-bit arithmetic datapath, a 16-register dual-port register file, a dedicated instruction decoder, and an 8-stage synchronous Finite State Machine (FSM).

---

## Repository Structure

```
16bit-risc-cpu/
├── .gitignore                          # ModelSim, simulator, and cache ignores
├── README.md                           # Comprehensive GitHub documentation
├── CS_PSD9_BryanHerdianto_2306210885.md # Original course study assignment report
├── doc/
│   └── cpu_architecture.md            # Detailed hardware architecture specification
├── src/
│   ├── cpu_pkg.vhd                     # Common package: opcodes, FSM states, types
│   ├── decoder.vhd                     # 16-bit Instruction Decoder
│   ├── alu.vhd                         # 8-bit Arithmetic Logic Unit (10 opcodes)
│   ├── registerfile.vhd                # 16x8-bit Dual-Port Register File
│   └── cpu.vhd                         # Top-level CPU core and FSM controller
└── sim/
    ├── cpu_tb.vhd                      # Comprehensive regression verification testbench
    └── run_sim.py                      # Automated simulation runner script for ModelSim
```

---

## Architecture Overview

```
                      +-----------------------------+
                      |   Instruction In (16 bits)  |
                      +--------------+--------------+
                                     |
                                     v
                           +-------------------+
                           |      DECODER      |
                           +---------+---------+
                                     | Opcode, Flags, Operands
                                     v
                        +-------------------------+
                        |      CPU Controller     |
                        |    8-State FSM Engine   |
                        +----+---------------+----+
                             |               |
              Read Addr, WrEn|               | Latch Data
                             v               v
                   +-------------------+   +-------------------+
                   |   REGISTER FILE   |   |        ALU        |
                   | 16 x 8-bit Regs   |-->| 8-bit Math Engine |
                   | Dual Read Ports   |<--| 10 Operations     |
                   +-------------------+   +-------------------+
                               Result Writeback
```

### Key Hardware Features
* **Instruction Word:** 16-bit instruction format supporting immediate and register-direct addressing.
* **Datapath:** 8-bit parallel arithmetic and logic operations.
* **Storage:** 16 general-purpose 8-bit registers ($R_0 \dots R_{15}$).
* **FSM Sequencing:** Deterministic 8-state synchronous execution cycle:
  $$\text{IDLE} \rightarrow \text{FETCH} \rightarrow \text{DECODE} \rightarrow \text{READ\_OPERAND} \rightarrow \text{READ\_ADDRESS} \rightarrow \text{EXECUTE} \rightarrow \text{WRITE} \rightarrow \text{COMPLETE}$$

---

## Instruction Set Architecture (ISA)

### Instruction Bitfield Format
```
 15       12 11   10 9         6 5                    0
+-----------+---+---+-----------+----------------------+
|  Opcode   | A | N |  Operand1 |       Operand2       |
|  (4 bits) |(1)|(1)| (4 bits)  |       (6 bits)       |
+-----------+---+---+-----------+----------------------+
```
* **Opcode `[15:12]`:** 4-bit ALU operation selector.
* **Address Flag `[11]` (`A`):**
  * `'0'`: Immediate value addressing (`Operand2[5:0]`).
  * `'1'`: Register-direct addressing (`Operand2[5:2]` selects source register).
* **Negative Flag `[10]` (`N`):**
  * `'1'`: Applies two's complement negation to the result before register write-back.
* **Operand 1 `[9:6]`:** 4-bit destination register address ($R_0 \dots R_{15}$).
* **Operand 2 `[5:0]`:** 6-bit immediate value ($0 \dots 63$) or 4-bit register address (`[5:2]`).

### Supported Opcodes
| Opcode | Mnemonic | Name | Operation |
| :---: | :---: | :--- | :--- |
| `0000` | **ADD** | Addition | $R_{dest} \leftarrow R_{dest} + Operand2$ |
| `0001` | **SUB** | Subtraction | $R_{dest} \leftarrow R_{dest} - Operand2$ |
| `0010` | **MUL** | Multiplication | $R_{dest} \leftarrow (R_{dest} \times Operand2)[7:0]$ |
| `0011` | **DIV** | Division | $R_{dest} \leftarrow R_{dest} / Operand2$ (guarded against zero) |
| `0100` | **AND** | Bitwise AND | $R_{dest} \leftarrow R_{dest} \text{ AND } Operand2$ |
| `0101` | **OR** | Bitwise OR | $R_{dest} \leftarrow R_{dest} \text{ OR } Operand2$ |
| `0110` | **XOR** | Bitwise XOR | $R_{dest} \leftarrow R_{dest} \text{ XOR } Operand2$ |
| `0111` | **NOT** | Bitwise NOT | $R_{dest} \leftarrow \text{NOT } R_{dest}$ |
| `1000` | **NEG_ADD**| Negative Addition | $R_{dest} \leftarrow R_{dest} + (\sim Operand2 + 1)$ |
| `1001` | **STOR** | Store / Move | $R_{dest} \leftarrow Operand2$ |

---

## Code Fixes & Architectural Enhancements

In refactoring the baseline code into this production-quality repository, several critical bugs were resolved:

1. **Unassigned ALU Input Signals (`input1`, `input2`):**
   * *Problem:* In the original code, `input1` and `input2` were declared as internal signals but were never assigned any values in the FSM, causing the ALU to compute operations on zeros (`0 + 0`, `0 - 0`, etc.).
   * *Fix:* In state `READ_ADDRESS`, `input1` correctly latches the destination register value from `register_value_dest_data_out`, and `input2` latches either the source register value or the zero-extended 6-bit immediate.

2. **Write-Back Signal Timing & Register Corruption:**
   * *Problem:* In the original `WRITE` state, `write_enable_in` was deasserted simultaneously with assigning `register_value_dest_data_in`, preventing the register file from writing the computed ALU result. In addition, when `address_flag = '1'`, the unassigned source write path would inadvertently overwrite the source register with zero.
   * *Fix:* Pipelined write-back cleanly: `register_addr_dest_data_in` and `register_value_dest_data_in` are set in `EXECUTE`, `write_enable_in` is asserted entering `WRITE`, and cleanly deasserted entering `COMPLETE`. Source registers are strictly protected against accidental overwrite.

3. **Divide-by-Zero Simulation Crash:**
   * *Problem:* In the original `alu.vhd`, division was executed unconditionally, causing runtime simulation crashes when dividing by zero.
   * *Fix:* Added an explicit division guard (`if unsigned(input2) /= 0 then ... else result1 <= (others => '0');`).

4. **Decoder Field Alignment:**
   * *Problem:* Ambiguity in register address bit-extraction when `address_flag = '1'`.
   * *Fix:* Standardized `decoder.vhd` so `operand2[5:2]` cleanly routes the 4-bit source register address while maintaining immediate value extraction on `operand2[5:0]`.

5. **Testbench Quality & Automated Verification:**
   * *Problem:* The baseline testbench relied on hardcoded zeros and reset after every single cycle without initializing data or checking results.
   * *Fix:* Built a comprehensive testbench (`sim/cpu_tb.vhd`) testing immediate loading, multi-register arithmetic, logic, two's complement writebacks, and the course reference sequence with automated completion reports.

---

## Verification & Simulation

### Running the Automated Simulation
Run the automated test runner with Python:

```bash
python sim/run_sim.py
```

### Manual Compilation with ModelSim / QuestaSim
From the repository root:

```bash
# 1. Create work library
vlib work

# 2. Compile VHDL source files in dependency order
vcom -work work src/cpu_pkg.vhd
vcom -work work src/decoder.vhd
vcom -work work src/alu.vhd
vcom -work work src/registerfile.vhd
vcom -work work src/cpu.vhd
vcom -work work sim/cpu_tb.vhd

# 3. Run simulation
vsim -c -lib work cpu_tb -do "run -all; quit -f"
```

### Verification Output Sample
```
# ** Note: STARTING 16-BIT RISC CPU VERIFICATION
# ** Note: [TEST 1] Loading immediate #20 into R0 (STOR R0, #20)...
# ** Note: [TEST 2] Loading immediate #5 into R1 (STOR R1, #5)...
# ** Note: [TEST 3] ADD R0, R1 (Expected R0 = 25)...
# ** Note: [TEST 4] SUB R0, R1 (Expected R0 = 20)...
# ** Note: [TEST 5] MUL R0, R1 (Expected R0 = 100)...
# ** Note: [TEST 6] DIV R0, R1 (Expected R0 = 20)...
# ** Note: [TEST 7] AND R0, R1 (Expected R0 = 4)...
# ** Note: [TEST 8] OR R0, R1 (Expected R0 = 5)...
# ** Note: [TEST 9] XOR R0, R1 (Expected R0 = 0)...
# ** Note: [TEST 10] NOT R0 (Expected R0 = 255)...
# ** Note: [TEST 11] NEG_ADD R0, R1 (Expected R0 = 250)...
# ** Note: [TEST 12] STOR with Negative Flag enabled (Two's Complement writeback)...
# ** Note: RUNNING ASSIGNMENT REFERENCE SEQUENCE
# ** Note: ALL CPU VERIFICATION TESTS COMPLETED SUCCESSFULLY!
```