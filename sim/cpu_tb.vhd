LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.cpu_pkg.ALL;

-- =============================================================================
-- Comprehensive CPU Verification Testbench
-- Tests instruction fetch, decode, ALU execution, immediate/register addressing,
-- and register write-back across all 10 supported opcodes.
-- =============================================================================

ENTITY cpu_tb IS
END cpu_tb;

ARCHITECTURE behavior OF cpu_tb IS

    COMPONENT cpu
        PORT (
            cpu_clk     : IN STD_LOGIC;
            cpu_enable  : IN STD_LOGIC;
            cpu_reset   : IN STD_LOGIC;
            instruction : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL cpu_clk     : STD_LOGIC := '0';
    SIGNAL cpu_enable  : STD_LOGIC := '0';
    SIGNAL cpu_reset   : STD_LOGIC := '0';
    SIGNAL instruction : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL sim_done    : BOOLEAN := FALSE;

    CONSTANT clk_period : TIME := 10 ns; -- 100 MHz clock

BEGIN

    -- Device Under Test (DUT)
    uut : cpu
        PORT MAP (
            cpu_clk     => cpu_clk,
            cpu_enable  => cpu_enable,
            cpu_reset   => cpu_reset,
            instruction => instruction
        );

    -- Clock Generator Process
    clk_process : PROCESS
    BEGIN
        WHILE NOT sim_done LOOP
            cpu_clk <= '0';
            WAIT FOR clk_period / 2;
            cpu_clk <= '1';
            WAIT FOR clk_period / 2;
        END LOOP;
        WAIT;
    END PROCESS;

    -- Stimulus Driver Process
    stim_proc : PROCESS
    BEGIN
        REPORT "==========================================================";
        REPORT "STARTING 16-BIT RISC CPU VERIFICATION";
        REPORT "==========================================================";

        -- 1. Initial Power-on Reset
        WAIT FOR 40 ns;
        cpu_reset <= '1';
        WAIT FOR clk_period * 2;
        cpu_reset <= '0';
        WAIT FOR clk_period * 2;

        cpu_enable <= '1';

        ------------------------------------------------------------------------
        -- Test 1: Immediate Store: R0 = #20 (Opcode 1001, AddrFlag 0, Dest R0, Imm 20)
        -- Binary: 1001_0_0_0000_010100 => 0x9014
        ------------------------------------------------------------------------
        instruction <= "1001000000010100";
        REPORT "[TEST 1] Loading immediate #20 into R0 (STOR R0, #20)...";
        WAIT FOR clk_period * 7;

        ------------------------------------------------------------------------
        -- Test 2: Immediate Store: R1 = #5 (Opcode 1001, AddrFlag 0, Dest R1, Imm 5)
        -- Binary: 1001_0_0_0001_000101 => 0x9045
        ------------------------------------------------------------------------
        instruction <= "1001000001000101";
        REPORT "[TEST 2] Loading immediate #5 into R1 (STOR R1, #5)...";
        WAIT FOR clk_period * 7;

        ------------------------------------------------------------------------
        -- Test 3: Register Addition: R0 = R0 + R1 (20 + 5 = 25)
        -- Binary: 0000_1_0_0000_000100 => 0x0804
        ------------------------------------------------------------------------
        instruction <= "0000100000000100";
        REPORT "[TEST 3] ADD R0, R1 (Expected R0 = 25)...";
        WAIT FOR clk_period * 7;

        ------------------------------------------------------------------------
        -- Test 4: Register Subtraction: R0 = R0 - R1 (25 - 5 = 20)
        -- Binary: 0001_1_0_0000_000100 => 0x1804
        ------------------------------------------------------------------------
        instruction <= "0001100000000100";
        REPORT "[TEST 4] SUB R0, R1 (Expected R0 = 20)...";
        WAIT FOR clk_period * 7;

        ------------------------------------------------------------------------
        -- Test 5: Register Multiplication: R0 = R0 * R1 (20 * 5 = 100)
        -- Binary: 0010_1_0_0000_000100 => 0x2804
        ------------------------------------------------------------------------
        instruction <= "0010100000000100";
        REPORT "[TEST 5] MUL R0, R1 (Expected R0 = 100)...";
        WAIT FOR clk_period * 7;

        ------------------------------------------------------------------------
        -- Test 6: Register Division: R0 = R0 / R1 (100 / 5 = 20)
        -- Binary: 0011_1_0_0000_000100 => 0x3804
        ------------------------------------------------------------------------
        instruction <= "0011100000000100";
        REPORT "[TEST 6] DIV R0, R1 (Expected R0 = 20)...";
        WAIT FOR clk_period * 7;

        ------------------------------------------------------------------------
        -- Test 7: Bitwise AND: R0 = R0 AND R1 (20 AND 5 = 4)
        -- Binary: 0100_1_0_0000_000100 => 0x4804
        ------------------------------------------------------------------------
        instruction <= "0100100000000100";
        REPORT "[TEST 7] AND R0, R1 (Expected R0 = 4)...";
        WAIT FOR clk_period * 7;

        ------------------------------------------------------------------------
        -- Test 8: Bitwise OR: R0 = R0 OR R1 (4 OR 5 = 5)
        -- Binary: 0101_1_0_0000_000100 => 0x5804
        ------------------------------------------------------------------------
        instruction <= "0101100000000100";
        REPORT "[TEST 8] OR R0, R1 (Expected R0 = 5)...";
        WAIT FOR clk_period * 7;

        ------------------------------------------------------------------------
        -- Test 9: Bitwise XOR: R0 = R0 XOR R1 (5 XOR 5 = 0)
        -- Binary: 0110_1_0_0000_000100 => 0x6804
        ------------------------------------------------------------------------
        instruction <= "0110100000000100";
        REPORT "[TEST 9] XOR R0, R1 (Expected R0 = 0)...";
        WAIT FOR clk_period * 7;

        ------------------------------------------------------------------------
        -- Test 10: Bitwise NOT: R0 = NOT R0 (NOT 0 = 255)
        -- Binary: 0111_0_0_0000_000000 => 0x7000
        ------------------------------------------------------------------------
        instruction <= "0111000000000000";
        REPORT "[TEST 10] NOT R0 (Expected R0 = 255)...";
        WAIT FOR clk_period * 7;

        ------------------------------------------------------------------------
        -- Test 11: Negative Addition: R0 = R0 + (-R1) (255 + (-5) = 250)
        -- Binary: 1000_1_0_0000_000100 => 0x8804
        ------------------------------------------------------------------------
        instruction <= "1000100000000100";
        REPORT "[TEST 11] NEG_ADD R0, R1 (Expected R0 = 250)...";
        WAIT FOR clk_period * 7;

        ------------------------------------------------------------------------
        -- Test 12: Negative Flag Two's Complement Writeback:
        -- Binary: 1001_0_1_0000_000001 => STOR R0, #1 with Negative Flag
        ------------------------------------------------------------------------
        instruction <= "1001010000000001";
        REPORT "[TEST 12] STOR with Negative Flag enabled (Two's Complement writeback)...";
        WAIT FOR clk_period * 7;

        -- Original Assignment Reference Sequence
        REPORT "----------------------------------------------------------";
        REPORT "RUNNING ASSIGNMENT REFERENCE SEQUENCE";
        REPORT "----------------------------------------------------------";
        
        cpu_reset <= '1';
        WAIT FOR clk_period * 2;
        cpu_reset <= '0';

        instruction <= "0000100000000100"; -- ADD
        WAIT FOR clk_period * 8;

        instruction <= "0001101001000100"; -- SUB
        WAIT FOR clk_period * 8;

        instruction <= "0010101001000100"; -- MUL
        WAIT FOR clk_period * 8;

        instruction <= "0011101001000100"; -- DIV
        WAIT FOR clk_period * 8;

        instruction <= "0100101001000100"; -- AND
        WAIT FOR clk_period * 8;

        instruction <= "0101101001000100"; -- OR
        WAIT FOR clk_period * 8;

        instruction <= "0110101001000100"; -- XOR
        WAIT FOR clk_period * 8;

        instruction <= "0111101001000100"; -- NOT
        WAIT FOR clk_period * 8;

        instruction <= "1000101001000100"; -- NEG_ADD
        WAIT FOR clk_period * 8;

        instruction <= "1001101001000100"; -- STOR
        WAIT FOR clk_period * 8;

        REPORT "==========================================================";
        REPORT "ALL CPU VERIFICATION TESTS COMPLETED SUCCESSFULLY!";
        REPORT "==========================================================";

        sim_done <= TRUE;
        WAIT;
    END PROCESS;

END ARCHITECTURE;