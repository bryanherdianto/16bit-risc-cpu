# Entity: decoder

- **File:** decoder.vhd
- **Brief:** Instruction Decoder
- **Details:** Decodes 16-bit CPU instructions into opcode, flags, and operand fields:

## Diagram

![Diagram](decoder.svg "Diagram")

## Description

- [15:12] Opcode (4 bits)
- [11] Address Flag (1 bit: '0' = Immediate, '1' = Register)
- [10] Negative Flag (1 bit: Two's complement writeback enable)
- [9:6] Operand 1 (4 bits: Destination Register Address)
- [5:0] Operand 2 (6 bits: Immediate Value or [5:2] Source Register Address)

## Ports

| Port name     | Direction | Type                           | Description                                                        |
| ------------- | --------- | ------------------------------ | ------------------------------------------------------------------ |
| cpu_clk       | in        | STD_LOGIC                      | Master CPU clock input                                             |
| cpu_enable    | in        | STD_LOGIC                      | Global CPU enable signal (active high)                             |
| instruction   | in        | STD_LOGIC_VECTOR (15 DOWNTO 0) | 16-bit instruction word input                                      |
| opcode        | out       | STD_LOGIC_VECTOR (3 DOWNTO 0)  | 4-bit decoded operation code                                       |
| address_flag  | out       | STD_LOGIC                      | Address mode flag ('0' = Immediate, '1' = Register)                |
| negative_flag | out       | STD_LOGIC                      | Two's complement writeback control flag                            |
| operand1      | out       | STD_LOGIC_VECTOR (3 DOWNTO 0)  | 4-bit destination register address                                 |
| operand2      | out       | STD_LOGIC_VECTOR (5 DOWNTO 0)  | 6-bit operand (immediate value or shifted source register address) |

## Processes

- decode_process
  - Has a sensitivity list of cpu_clk
  - Synchronous instruction decoding process triggered on the rising edge of cpu_clk
