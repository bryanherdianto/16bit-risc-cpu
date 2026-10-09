LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.cpu_pkg.ALL;

-- =============================================================================
-- Top-Level 16-Bit RISC CPU
-- Integrates Instruction Decoder, 16x8-bit Register File, and 8-bit ALU.
-- FSM Control States:
--   IDLE -> FETCH -> DECODE -> READ_OPERAND -> READ_ADDRESS -> EXECUTE -> WRITE -> COMPLETE
-- =============================================================================

ENTITY cpu IS
    PORT (
        cpu_clk     : IN STD_LOGIC;
        cpu_enable  : IN STD_LOGIC;
        cpu_reset   : IN STD_LOGIC;
        instruction : IN STD_LOGIC_VECTOR (15 DOWNTO 0)
    );
END cpu;

ARCHITECTURE Behavioral OF cpu IS

    -- Subcomponent Declarations
    COMPONENT registerfile
        PORT (
            cpu_clk                      : IN  STD_LOGIC;
            cpu_enable                   : IN  STD_LOGIC;
            write_enable_in              : IN  STD_LOGIC;
            address_flag                 : IN  STD_LOGIC;
            negative_flag                : IN  STD_LOGIC;
            register_addr_dest_data_in   : IN  STD_LOGIC_VECTOR (3 DOWNTO 0);
            register_addr_src_data_in    : IN  STD_LOGIC_VECTOR (3 DOWNTO 0);
            register_value_dest_data_in  : IN  STD_LOGIC_VECTOR (7 DOWNTO 0);
            register_value_src_data_in   : IN  STD_LOGIC_VECTOR (7 DOWNTO 0);
            register_value_dest_data_out : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
            register_value_src_data_out  : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT decoder
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
    END COMPONENT;

    COMPONENT alu
        PORT (
            cpu_clk    : IN  STD_LOGIC;
            cpu_enable : IN  STD_LOGIC;
            alu_enable : IN  STD_LOGIC;
            opcode     : IN  STD_LOGIC_VECTOR (3 DOWNTO 0);
            input1     : IN  STD_LOGIC_VECTOR (7 DOWNTO 0);
            input2     : IN  STD_LOGIC_VECTOR (7 DOWNTO 0);
            result1    : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
            result2    : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
        );
    END COMPONENT;

    -- Internal FSM Signals
    SIGNAL state           : state_type := IDLE;
    SIGNAL program_counter : INTEGER := 0;

    -- Decoder Interconnects
    SIGNAL instruction_raw : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL opcode          : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL address_flag    : STD_LOGIC := '0';
    SIGNAL negative_flag   : STD_LOGIC := '0';
    SIGNAL operand1        : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL operand2        : STD_LOGIC_VECTOR(5 DOWNTO 0) := (OTHERS => '0');

    -- Register File Interconnects
    SIGNAL write_enable_in              : STD_LOGIC := '0';
    SIGNAL register_addr_dest_data_in   : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL register_addr_src_data_in    : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL register_value_dest_data_in  : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL register_value_src_data_in   : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL register_value_dest_data_out : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL register_value_src_data_out  : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');

    -- ALU Interconnects
    SIGNAL alu_enable  : STD_LOGIC := '0';
    SIGNAL input1      : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL input2      : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL alu_result1 : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL alu_result2 : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');

BEGIN

    -- Register File Instance
    cpu_registerfile : registerfile
        PORT MAP (
            cpu_clk                      => cpu_clk,
            cpu_enable                   => cpu_enable,
            write_enable_in              => write_enable_in,
            address_flag                 => address_flag,
            negative_flag                => negative_flag,
            register_addr_dest_data_in   => register_addr_dest_data_in,
            register_addr_src_data_in    => register_addr_src_data_in,
            register_value_dest_data_in  => register_value_dest_data_in,
            register_value_src_data_in   => register_value_src_data_in,
            register_value_dest_data_out => register_value_dest_data_out,
            register_value_src_data_out  => register_value_src_data_out
        );

    -- Instruction Decoder Instance
    cpu_decoder : decoder
        PORT MAP (
            cpu_clk       => cpu_clk,
            cpu_enable    => cpu_enable,
            instruction   => instruction_raw,
            opcode        => opcode,
            address_flag  => address_flag,
            negative_flag => negative_flag,
            operand1      => operand1,
            operand2      => operand2
        );

    -- Arithmetic Logic Unit Instance
    cpu_alu : alu
        PORT MAP (
            cpu_clk    => cpu_clk,
            cpu_enable => cpu_enable,
            alu_enable => alu_enable,
            opcode     => opcode,
            input1     => input1,
            input2     => input2,
            result1    => alu_result1,
            result2    => alu_result2
        );

    -- FSM Execution Process
    PROCESS (cpu_clk, cpu_reset) IS
    BEGIN
        IF cpu_reset = '1' THEN
            state                       <= IDLE;
            program_counter             <= 0;
            instruction_raw             <= (OTHERS => '0');
            alu_enable                  <= '0';
            write_enable_in             <= '0';
            input1                      <= (OTHERS => '0');
            input2                      <= (OTHERS => '0');
            register_addr_dest_data_in  <= (OTHERS => '0');
            register_addr_src_data_in   <= (OTHERS => '0');
            register_value_dest_data_in <= (OTHERS => '0');

        ELSIF rising_edge(cpu_clk) THEN
            program_counter <= program_counter + 1;

            CASE state IS
                WHEN IDLE =>
                    write_enable_in <= '0';
                    alu_enable      <= '0';
                    IF cpu_enable = '1' THEN
                        state <= FETCH;
                    END IF;

                WHEN FETCH =>
                    instruction_raw <= instruction;
                    state           <= DECODE;

                WHEN DECODE =>
                    -- Set up register addresses to read operands
                    register_addr_dest_data_in <= operand1;
                    register_addr_src_data_in  <= operand2(5 DOWNTO 2);
                    write_enable_in            <= '0';
                    state                      <= READ_OPERAND;

                WHEN READ_OPERAND =>
                    -- Register file outputs become valid on next cycle
                    state <= READ_ADDRESS;

                WHEN READ_ADDRESS =>
                    -- Latch operands into ALU inputs
                    input1 <= register_value_dest_data_out;

                    IF address_flag = '1' THEN
                        input2 <= register_value_src_data_out;
                    ELSE
                        input2 <= "00" & operand2; -- Immediate value zero-extended to 8 bits
                    END IF;

                    alu_enable <= '1';
                    state      <= EXECUTE;

                WHEN EXECUTE =>
                    -- ALU completes operation; setup register writeback
                    alu_enable                 <= '0';
                    write_enable_in            <= '1';
                    register_addr_dest_data_in <= operand1;

                    IF negative_flag = '1' THEN
                        register_value_dest_data_in <= STD_LOGIC_VECTOR(unsigned(NOT alu_result1) + 1);
                    ELSE
                        register_value_dest_data_in <= alu_result1;
                    END IF;

                    state <= WRITE;

                WHEN WRITE =>
                    -- Register file writes at this clock edge; deassert write enable
                    write_enable_in <= '0';
                    state           <= COMPLETE;

                WHEN COMPLETE =>
                    IF cpu_enable = '1' THEN
                        state <= FETCH;
                    ELSE
                        state <= IDLE;
                    END IF;

            END CASE;
        END IF;
    END PROCESS;

END Behavioral;
