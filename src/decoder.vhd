LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- =============================================================================
-- Instruction Decoder
-- Decodes 16-bit CPU instructions into opcode, flags, and operand fields
-- Instruction Format:
--   [15:12] Opcode        (4 bits)
--   [11]    Address Flag  (1 bit: '0' = Immediate, '1' = Register)
--   [10]    Negative Flag (1 bit: Two's complement writeback enable)
--   [9:6]   Operand 1     (4 bits: Destination Register Address)
--   [5:0]   Operand 2     (6 bits: Immediate Value or [5:2] Source Register Address)
-- =============================================================================

ENTITY decoder IS
    PORT (
        cpu_clk       : IN  STD_LOGIC;
        cpu_enable    : IN  STD_LOGIC;
        instruction   : IN  STD_LOGIC_VECTOR (15 DOWNTO 0);
        opcode        : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
        address_flag  : OUT STD_LOGIC;
        negative_flag : OUT STD_LOGIC;
        operand1      : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
        operand2      : OUT STD_LOGIC_VECTOR (5 DOWNTO 0)
    );
END decoder;

ARCHITECTURE Behavioral OF decoder IS
BEGIN

    PROCESS (cpu_clk)
    BEGIN
        IF rising_edge(cpu_clk) THEN
            IF cpu_enable = '1' THEN
                opcode        <= instruction(15 DOWNTO 12);
                address_flag  <= instruction(11);
                negative_flag <= instruction(10);
                operand1      <= instruction(9 DOWNTO 6);

                -- When address_flag is '1', bits [5:2] form the 4-bit source register address
                -- When address_flag is '0', bits [5:0] form the 6-bit immediate value
                IF instruction(11) = '1' THEN
                    operand2 <= instruction(5 DOWNTO 2) & "00";
                ELSE
                    operand2 <= instruction(5 DOWNTO 0);
                END IF;
            ELSE
                opcode        <= (OTHERS => '0');
                address_flag  <= '0';
                negative_flag <= '0';
                operand1      <= (OTHERS => '0');
                operand2      <= (OTHERS => '0');
            END IF;
        END IF;
    END PROCESS;

END Behavioral;
