# 16-Bit RISC CPU Architecture Specification

## 1. Overview
This document specifies the internal architecture, instruction encoding, FSM sequencing, and datapath of the **16-Bit RISC CPU** implemented in VHDL.

The CPU utilizes a Harvard-like architecture with a 16-bit instruction word, an 8-bit arithmetic datapath, a 16-register dual-read register file, and an 8-state synchronous Finite State Machine (FSM).

---

## 2. Instruction Word Format

Every instruction is exactly 16 bits wide:

```
 15       12 11   10 9         6 5                    0
+-----------+---+---+-----------+----------------------+
|  Opcode   | A | N |  Operand1 |       Operand2       |
|  (4 bits) |(1)|(1)| (4 bits)  |       (6 bits)       |
+-----------+---+---+-----------+----------------------+
```

### Field Definitions:
| Field | Bit Range | Description |
| :--- | :--- | :--- |
| **Opcode** | `[15:12]` | 4-bit operation code defining the ALU function. |
| **Address Flag (`A`)** | `[11]` | **'0'**: `Operand2` is an immediate value (`[5:0]`).<br>**'1'**: `Operand2` is a source register address (`[5:2]`). |
| **Negative Flag (`N`)** | `[10]` | **'1'**: Result is converted to two's complement before register write-back. |
| **Operand 1** | `[9:6]` | 4-bit destination register address ($R_0 \dots R_{15}$). |
| **Operand 2** | `[5:0]` | When $A=0$: 6-bit unsigned immediate value ($0 \dots 63$).<br>When $A=1$: Bits `[5:2]` encode the 4-bit source register address ($R_0 \dots R_{15}$). |

---

## 3. Instruction Set Architecture (ISA)

| Opcode | Mnemonic | Name | Operation |
| :---: | :---: | :--- | :--- |
| `0000` | **ADD** | Addition | $R_{dest} \leftarrow R_{dest} + Operand2$ |
| `0001` | **SUB** | Subtraction | $R_{dest} \leftarrow R_{dest} - Operand2$ |
| `0010` | **MUL** | Multiplication | $R_{dest} \leftarrow (R_{dest} \times Operand2)[7:0]$ |
| `0011` | **DIV** | Division | $R_{dest} \leftarrow R_{dest} / Operand2$ (guarded for div-by-0) |
| `0100` | **AND** | Bitwise AND | $R_{dest} \leftarrow R_{dest} \text{ AND } Operand2$ |
| `0101` | **OR** | Bitwise OR | $R_{dest} \leftarrow R_{dest} \text{ OR } Operand2$ |
| `0110` | **XOR** | Bitwise XOR | $R_{dest} \leftarrow R_{dest} \text{ XOR } Operand2$ |
| `0111` | **NOT** | Bitwise NOT | $R_{dest} \leftarrow \text{NOT } R_{dest}$ |
| `1000` | **NEG_ADD**| Negative Addition | $R_{dest} \leftarrow R_{dest} + (\sim Operand2 + 1)$ |
| `1001` | **STOR** | Store / Move | $R_{dest} \leftarrow Operand2$ |

---

## 4. Finite State Machine (FSM)

Each instruction cycle is executed across 7 synchronous states:

```
 [IDLE] ---> [FETCH] ---> [DECODE] ---> [READ_OPERAND]
                                              |
 [COMPLETE] <-- [WRITE] <-- [EXECUTE] <-- [READ_ADDRESS]
```

### State Detailed Description:
1. **IDLE**: The CPU sits idle awaiting `cpu_enable = '1'`. All internal control signals remain deasserted.
2. **FETCH**: Samples the external 16-bit `instruction` into the internal register `instruction_raw`.
3. **DECODE**: The `decoder` component partitions the instruction into opcode, address flag, negative flag, and operand addresses. Read addresses are applied to the register file.
4. **READ_OPERAND**: The dual-port register file reads $R_{dest}$ and $R_{src}$.
5. **READ_ADDRESS**: Operands are latched into ALU inputs (`input1` receives $R_{dest}$, `input2` receives $R_{src}$ or the zero-extended 6-bit immediate). `alu_enable` asserts.
6. **EXECUTE**: The ALU computes the arithmetic/logic result. Write-back data and address are prepared.
7. **WRITE**: The destination register is written synchronously in the register file.
8. **COMPLETE**: Clears write enables and loops back to `FETCH` if `cpu_enable` remains active, or returns to `IDLE`.

---

## 5. Register File Organization

* **Depth:** 16 Registers ($R_0$ through $R_{15}$).
* **Width:** 8 Bits per register.
* **Dual Read Ports:**
  * Port A (`register_value_dest_data_out`): Reads $R_{dest}$ from address `operand1`.
  * Port B (`register_value_src_data_out`): Reads $R_{src}$ from address `operand2(5 downto 2)` when $A=1$.
* **Single Write Port:**
  * Writes to address `register_addr_dest_data_in` on the rising clock edge when `write_enable_in = '1'`.