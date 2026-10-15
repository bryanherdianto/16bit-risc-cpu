
# Package: cpu_pkg 
- **File**: cpu_pkg.vhd
- **Brief:**  CPU package containing FSM state types, opcode constants, and register file definitions.

## Description


## Constants

| Name       | Type                         | Value  | Description                                           |
| ---------- | ---------------------------- | ------ | ----------------------------------------------------- |
| OP_ADD     | STD_LOGIC_VECTOR(3 DOWNTO 0) | "0000" | Addition (R_dest = R_dest + Operand2)                 |
| OP_SUB     | STD_LOGIC_VECTOR(3 DOWNTO 0) | "0001" | Subtraction (R_dest = R_dest - Operand2)              |
| OP_MUL     | STD_LOGIC_VECTOR(3 DOWNTO 0) | "0010" | Multiplication (R_dest = (R_dest * Operand2)[7:0])    |
| OP_DIV     | STD_LOGIC_VECTOR(3 DOWNTO 0) | "0011" | Division (R_dest = R_dest / Operand2)                 |
| OP_AND     | STD_LOGIC_VECTOR(3 DOWNTO 0) | "0100" | Bitwise AND (R_dest = R_dest AND Operand2)            |
| OP_OR      | STD_LOGIC_VECTOR(3 DOWNTO 0) | "0101" | Bitwise OR (R_dest = R_dest OR Operand2)              |
| OP_XOR     | STD_LOGIC_VECTOR(3 DOWNTO 0) | "0110" | Bitwise XOR (R_dest = R_dest XOR Operand2)            |
| OP_NOT     | STD_LOGIC_VECTOR(3 DOWNTO 0) | "0111" | Bitwise NOT (R_dest = NOT R_dest)                     |
| OP_NEG_ADD | STD_LOGIC_VECTOR(3 DOWNTO 0) | "1000" | Negative Addition (R_dest = R_dest + (~Operand2 + 1)) |
| OP_STOR    | STD_LOGIC_VECTOR(3 DOWNTO 0) | "1001" | Store / Move (R_dest = Operand2)                      |

## Types

| Name       | Type | Description                                     |
| ---------- | ---- | ----------------------------------------------- |
| reg_file_t |      | Register File Type (16 registers x 8 bits each) |

## Enums


### *state_type*
 CPU FSM control states
| Name         | Description                                           |
| ------------ | ----------------------------------------------------- |
| IDLE         | Wait for cpu_enable activation                        |
| FETCH        | Latch 16-bit instruction from memory/input            |
| DECODE       | Extract opcode, flags, and operand register addresses |
| READ_OPERAND | Read operands from register file                      |
| READ_ADDRESS | Setup operands into ALU inputs                        |
| EXECUTE      | Execute ALU arithmetic or logic operation             |
| WRITE        | Write result back into destination register           |
| COMPLETE     | Instruction cycle complete                            |

