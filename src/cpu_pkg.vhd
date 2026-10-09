LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

PACKAGE cpu_pkg IS

    -- CPU FSM States
    TYPE state_type IS (IDLE, FETCH, DECODE, READ_OPERAND, READ_ADDRESS, EXECUTE, WRITE, COMPLETE);

    -- Opcode Definitions
    CONSTANT OP_ADD     : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0000"; -- Addition (R_dest = R_dest + Operand2)
    CONSTANT OP_SUB     : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0001"; -- Subtraction (R_dest = R_dest - Operand2)
    CONSTANT OP_MUL     : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0010"; -- Multiplication (R_dest = (R_dest * Operand2)[7:0])
    CONSTANT OP_DIV     : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0011"; -- Division (R_dest = R_dest / Operand2)
    CONSTANT OP_AND     : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0100"; -- Bitwise AND (R_dest = R_dest AND Operand2)
    CONSTANT OP_OR      : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0101"; -- Bitwise OR (R_dest = R_dest OR Operand2)
    CONSTANT OP_XOR     : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0110"; -- Bitwise XOR (R_dest = R_dest XOR Operand2)
    CONSTANT OP_NOT     : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0111"; -- Bitwise NOT (R_dest = NOT R_dest)
    CONSTANT OP_NEG_ADD : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1000"; -- Negative Addition (R_dest = R_dest + (~Operand2 + 1))
    CONSTANT OP_STOR    : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1001"; -- Store / Move (R_dest = Operand2)

    -- Register File Type (16 registers x 8 bits)
    TYPE reg_file_t IS ARRAY (0 TO 15) OF STD_LOGIC_VECTOR(7 DOWNTO 0);

END PACKAGE cpu_pkg;
