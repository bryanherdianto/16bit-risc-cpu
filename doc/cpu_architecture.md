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

### Multi-Cycle FSM Control & Timing Table

Each instruction takes exactly **7 clock cycles** from `FETCH` to `COMPLETE` once `cpu_enable = '1'`. Below is the exact cycle-by-cycle RTL behavior of the controller:

| Cycle | FSM State | `alu_enable` | `write_enable_in` | Active RTL Operations & Signal Transfers | Next State |
| --- | --- | --- | --- | --- | --- |
| **0** | **`IDLE`** | `'0'`<br> | `'0'`<br> | Holds control enables low; waits for `cpu_enable = '1'`.

 | `FETCH` (if `cpu_enable='1'`)

 |
| **1** | **`FETCH`** | `'0'`<br> | `'0'`<br> | Latches external `instruction[15:0]` into internal `instruction_raw`.

 | `DECODE`<br> |
| **2** | **`DECODE`** | `'0'`<br> | `'0'`<br> | `cpu_decoder` outputs `opcode`, `address_flag`, `negative_flag`, `operand1`, and `operand2`. FSM drives `register_addr_dest_data_in <= operand1` and `register_addr_src_data_in <= operand2(5 DOWNTO 2)`.

 | `READ_OPERAND`<br> |
| **3** | **`READ_OPERAND`** | `'0'`<br> | `'0'`<br> | Wait state allowing synchronous `cpu_registerfile` read ports (`register_value_dest_data_out` and `register_value_src_data_out`) to latch valid data.

 | `READ_ADDRESS`<br> |
| **4** | **`READ_ADDRESS`** | `'1'`<br> | `'0'`<br> | Latches `input1 <= register_value_dest_data_out`. Multiplexes `input2`: selects `register_value_src_data_out` if `address_flag = '1'`, else zero-extended immediate `"00" & operand2`. Asserts `alu_enable <= '1'`.

 | `EXECUTE`<br> |
| **5** | **`EXECUTE`** | `'0'`<br> | `'1'`<br> | `cpu_alu` computes `alu_result1`. FSM deasserts `alu_enable <= '0'`, asserts `write_enable_in <= '1'`, sets `register_addr_dest_data_in <= operand1`, and routes `alu_result1` (or its two's complement if `negative_flag = '1'`) to `register_value_dest_data_in`.

 | `WRITE`<br> |
| **6** | **`WRITE`** | `'0'`<br> | `'0'`<br> | `cpu_registerfile` writes `register_value_dest_data_in` into `reg_file(dest_idx)` on the clock edge. FSM deasserts `write_enable_in <= '0'`.

 | `COMPLETE`<br> |
| **7** | **`COMPLETE`** | `'0'`<br> | `'0'`<br> | Instruction cycle complete. Loops directly back to `FETCH` for the next instruction if `cpu_enable = '1'`, or returns to `IDLE` if `cpu_enable = '0'`.

 | `FETCH` or `IDLE`<br> |

---

## 5. Register File Organization

* **Depth:** 16 Registers ($R_0$ through $R_{15}$).
* **Width:** 8 Bits per register.
* **Dual Read Ports:**
  * Port A (`register_value_dest_data_out`): Reads $R_{dest}$ from address `operand1`.
  * Port B (`register_value_src_data_out`): Reads $R_{src}$ from address `operand2(5 downto 2)` when $A=1$.
* **Single Write Port:**
  * Writes to address `register_addr_dest_data_in` on the rising clock edge when `write_enable_in = '1'`.