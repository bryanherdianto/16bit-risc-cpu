# Entity: alu

- **File:** alu.vhd
- **Brief:** Arithmetic Logic Unit (ALU)
- **Details:** Performs 8-bit arithmetic and logic operations based on a 4-bit opcode.

## Diagram

![Diagram](alu.svg "Diagram")

## Ports

| Port name  | Direction | Type                          | Description                                                  |
| ---------- | --------- | ----------------------------- | ------------------------------------------------------------ |
| cpu_clk    | in        | STD_LOGIC                     | Master CPU clock input                                       |
| cpu_enable | in        | STD_LOGIC                     | Global CPU enable signal (active high)                       |
| alu_enable | in        | STD_LOGIC                     | ALU operation execution enable (active high)                 |
| opcode     | in        | STD_LOGIC_VECTOR (3 DOWNTO 0) | 4-bit operation code selector                                |
| input1     | in        | STD_LOGIC_VECTOR (7 DOWNTO 0) | 8-bit primary operand (destination register value)           |
| input2     | in        | STD_LOGIC_VECTOR (7 DOWNTO 0) | 8-bit secondary operand (source register value or immediate) |
| result1    | out       | STD_LOGIC_VECTOR (7 DOWNTO 0) | 8-bit computation result output                              |
| result2    | out       | STD_LOGIC_VECTOR (7 DOWNTO 0) | 8-bit secondary passthrough output (input2 value)            |

## Processes

- alu_process
  - Has a sensitivity list of cpu_clk
  - Synchronous ALU evaluation process triggered on the rising edge of cpu_clk
