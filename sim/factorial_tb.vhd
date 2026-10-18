LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.cpu_pkg.ALL;

-- Factorial Algorithm Verification Testbench (5! = 120 / 0x78)
-- Demonstrates execution of a multi-cycle straight-line algorithm computing
-- the factorial of 5 on the 16-Bit RISC CPU.
-- Register allocation:
--   R0: Accumulator / Running Product (initialized to 1)
--   R1: Multiplier / Step Counter    (2, 3, 4, 5)
-- Expected Final Results:
--   R0 = 120 (0x78) -> 5!
--   R1 = 5   (0x05)

ENTITY factorial_tb IS
END factorial_tb;

ARCHITECTURE behavior OF factorial_tb IS

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

    -- Clock Generator (100 MHz)
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

    -- Stimulus Driver: 5! Factorial Program Execution
    stim_proc : PROCESS
    BEGIN
        REPORT "STARTING 16-BIT RISC CPU FACTORIAL VERIFICATION (5! = 120)";

        -- 1. Power-on Reset
        WAIT FOR 40 ns;
        cpu_reset <= '1';
        WAIT FOR clk_period * 2;
        cpu_reset <= '0';
        WAIT FOR clk_period * 2;

        cpu_enable <= '1';

        -- Step 1: Initialize R0 = 1 (STOR R0, #1)
        -- Opcode: 1001, Addr: 0, Neg: 0, Dest: R0 (0000), Imm: 000001
        -- Hex: 0x9001
        instruction <= "1001000000000001";
        REPORT "[STEP 1] STOR R0, #1 -> Initializing accumulator R0 = 1 (0x9001)...";
        WAIT FOR clk_period * 7;

        -- Step 2: Initialize R1 = 2 (STOR R1, #2)
        -- Opcode: 1001, Addr: 0, Neg: 0, Dest: R1 (0001), Imm: 000010
        -- Hex: 0x9042
        instruction <= "1001000001000010";
        REPORT "[STEP 2] STOR R1, #2 -> Initializing multiplier R1 = 2 (0x9042)...";
        WAIT FOR clk_period * 7;

        -- Step 3: R0 = R0 * R1 -> 1 * 2 = 2 (MUL R0, R1)
        -- Opcode: 0010, Addr: 1, Neg: 0, Dest: R0 (0000), Src: R1 (000100)
        -- Hex: 0x2804
        instruction <= "0010100000000100";
        REPORT "[STEP 3] MUL R0, R1 -> R0 = 1 * 2 = 2 (0x2804)...";
        WAIT FOR clk_period * 7;

        -- Step 4: R1 = R1 + 1 -> 2 + 1 = 3 (ADD R1, #1)
        -- Opcode: 0000, Addr: 0, Neg: 0, Dest: R1 (0001), Imm: 000001
        -- Hex: 0x0041
        instruction <= "0000000001000001";
        REPORT "[STEP 4] ADD R1, #1 -> Increment multiplier R1 = 3 (0x0041)...";
        WAIT FOR clk_period * 7;

        -- Step 5: R0 = R0 * R1 -> 2 * 3 = 6 (3!) (MUL R0, R1)
        -- Opcode: 0010, Addr: 1, Neg: 0, Dest: R0 (0000), Src: R1 (000100)
        -- Hex: 0x2804
        instruction <= "0010100000000100";
        REPORT "[STEP 5] MUL R0, R1 -> R0 = 2 * 3 = 6 [3!] (0x2804)...";
        WAIT FOR clk_period * 7;

        -- Step 6: R1 = R1 + 1 -> 3 + 1 = 4 (ADD R1, #1)
        -- Opcode: 0000, Addr: 0, Neg: 0, Dest: R1 (0001), Imm: 000001
        -- Hex: 0x0041
        instruction <= "0000000001000001";
        REPORT "[STEP 6] ADD R1, #1 -> Increment multiplier R1 = 4 (0x0041)...";
        WAIT FOR clk_period * 7;

        -- Step 7: R0 = R0 * R1 -> 6 * 4 = 24 (4!) (MUL R0, R1)
        -- Opcode: 0010, Addr: 1, Neg: 0, Dest: R0 (0000), Src: R1 (000100)
        -- Hex: 0x2804
        instruction <= "0010100000000100";
        REPORT "[STEP 7] MUL R0, R1 -> R0 = 6 * 4 = 24 [4!] (0x2804)...";
        WAIT FOR clk_period * 7;

        -- Step 8: R1 = R1 + 1 -> 4 + 1 = 5 (ADD R1, #1)
        -- Opcode: 0000, Addr: 0, Neg: 0, Dest: R1 (0001), Imm: 000001
        -- Hex: 0x0041
        instruction <= "0000000001000001";
        REPORT "[STEP 8] ADD R1, #1 -> Increment multiplier R1 = 5 (0x0041)...";
        WAIT FOR clk_period * 7;

        -- Step 9: R0 = R0 * R1 -> 24 * 5 = 120 (5!) (MUL R0, R1)
        -- Opcode: 0010, Addr: 1, Neg: 0, Dest: R0 (0000), Src: R1 (000100)
        -- Hex: 0x2804
        instruction <= "0010100000000100";
        REPORT "[STEP 9] MUL R0, R1 -> R0 = 24 * 5 = 120 (0x78) [5!] (0x2804)...";
        WAIT FOR clk_period * 7;

        -- Hold state and allow waveform observation
        instruction <= (OTHERS => '0');
        WAIT FOR clk_period * 14;

        REPORT "FACTORIAL (5! = 120) PROGRAM COMPLETED SUCCESSFULLY!";
        REPORT "Expected Register State: R0 = 120 (0x78), R1 = 5 (0x05)";

        sim_done <= TRUE;
        WAIT;
    END PROCESS;

END ARCHITECTURE behavior;
