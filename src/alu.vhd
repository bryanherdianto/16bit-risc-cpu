LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

--! @brief Arithmetic Logic Unit (ALU)
--! @details Performs 8-bit arithmetic and logic operations based on a 4-bit opcode.
ENTITY alu IS
    PORT (
        cpu_clk    : IN  STD_LOGIC;                      --! Master CPU clock input
        cpu_enable : IN  STD_LOGIC;                      --! Global CPU enable signal (active high)
        alu_enable : IN  STD_LOGIC;                      --! ALU operation execution enable (active high)
        opcode     : IN  STD_LOGIC_VECTOR (3 DOWNTO 0);  --! 4-bit operation code selector
        input1     : IN  STD_LOGIC_VECTOR (7 DOWNTO 0);  --! 8-bit primary operand (destination register value)
        input2     : IN  STD_LOGIC_VECTOR (7 DOWNTO 0);  --! 8-bit secondary operand (source register value or immediate)
        result1    : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);  --! 8-bit computation result output
        result2    : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)   --! 8-bit secondary passthrough output (input2 value)
    );
END alu;

ARCHITECTURE Behavioral OF alu IS
BEGIN

    --! Synchronous ALU evaluation process triggered on the rising edge of cpu_clk
    alu_process: PROCESS (cpu_clk)
        VARIABLE mult : UNSIGNED(15 DOWNTO 0);
    BEGIN
        IF rising_edge(cpu_clk) THEN
            IF cpu_enable = '1' AND alu_enable = '1' THEN
                result2 <= input2;

                CASE opcode IS
                    WHEN "0000" => -- ADD
                        result1 <= STD_LOGIC_VECTOR(unsigned(input1) + unsigned(input2));

                    WHEN "0001" => -- SUB
                        result1 <= STD_LOGIC_VECTOR(unsigned(input1) - unsigned(input2));

                    WHEN "0010" => -- MUL
                        mult    := unsigned(input1) * unsigned(input2);
                        result1 <= STD_LOGIC_VECTOR(mult(7 DOWNTO 0));

                    WHEN "0011" => -- DIV (Guarded against divide-by-zero)
                        IF unsigned(input2) /= 0 THEN
                            result1 <= STD_LOGIC_VECTOR(unsigned(input1) / unsigned(input2));
                        ELSE
                            result1 <= (OTHERS => '0');
                        END IF;

                    WHEN "0100" => -- AND
                        result1 <= input1 AND input2;

                    WHEN "0101" => -- OR
                        result1 <= input1 OR input2;

                    WHEN "0110" => -- XOR
                        result1 <= input1 XOR input2;

                    WHEN "0111" => -- NOT
                        result1 <= NOT input1;

                    WHEN "1000" => -- NEG_ADD (input1 + two's complement of input2)
                        result1 <= STD_LOGIC_VECTOR(unsigned(input1) + unsigned(NOT input2) + 1);

                    WHEN "1001" => -- STOR (Pass input2 to result1)
                        result1 <= input2;

                    WHEN OTHERS =>
                        result1 <= (OTHERS => '0');
                END CASE;
            ELSE
                result1 <= (OTHERS => '0');
                result2 <= (OTHERS => '0');
            END IF;
        END IF;
    END PROCESS;

END Behavioral;
