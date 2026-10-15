LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

--! @brief Register File (16 Registers x 8 bits each)
--! @details Supports dual-read ports (destination & source) and synchronous write back.
--! Provides optional two's complement transformation on the source register read path.
ENTITY registerfile IS
    PORT (
        cpu_clk                      : IN  STD_LOGIC;                     --! Master CPU clock input
        cpu_enable                   : IN  STD_LOGIC;                     --! Global CPU enable signal (active high)
        write_enable_in              : IN  STD_LOGIC;                     --! Write enable control ('1' = Write, '0' = Read)
        address_flag                 : IN  STD_LOGIC;                     --! Address mode flag ('1' = Source register valid, '0' = Immediate mode)
        negative_flag                : IN  STD_LOGIC;                     --! Negative flag enable for two's complement writeback
        register_addr_dest_data_in   : IN  STD_LOGIC_VECTOR (3 DOWNTO 0); --! 4-bit destination register address input
        register_addr_src_data_in    : IN  STD_LOGIC_VECTOR (3 DOWNTO 0); --! 4-bit source register address input
        register_value_dest_data_in  : IN  STD_LOGIC_VECTOR (7 DOWNTO 0); --! 8-bit data input to write into destination register
        register_value_src_data_in   : IN  STD_LOGIC_VECTOR (7 DOWNTO 0); --! 8-bit secondary data input
        register_value_dest_data_out : OUT STD_LOGIC_VECTOR (7 DOWNTO 0); --! 8-bit data output read from destination register
        register_value_src_data_out  : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)  --! 8-bit data output read from source register
    );
END registerfile;

ARCHITECTURE Behavioral OF registerfile IS
    --! 16-element array of 8-bit std_logic_vector registers
    TYPE reg_array IS ARRAY(0 TO 15) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    --! Internal register array storage (R0 to R15)
    SIGNAL reg_file : reg_array := (OTHERS => x"00");

BEGIN

    --! Synchronous register file read and write access process
    reg_process: PROCESS (cpu_clk)
        VARIABLE dest_idx : INTEGER RANGE 0 TO 15;
        VARIABLE src_idx  : INTEGER RANGE 0 TO 15;
    BEGIN
        IF rising_edge(cpu_clk) THEN
            dest_idx := to_integer(unsigned(register_addr_dest_data_in));
            src_idx  := to_integer(unsigned(register_addr_src_data_in));

            IF cpu_enable = '1' THEN
                -- Read Operation (write_enable_in = '0')
                IF write_enable_in = '0' THEN
                    register_value_dest_data_out <= reg_file(dest_idx);

                    IF address_flag = '1' THEN
                        IF negative_flag = '1' THEN
                            register_value_src_data_out <= STD_LOGIC_VECTOR(unsigned(NOT reg_file(src_idx)) + 1);
                        ELSE
                            register_value_src_data_out <= reg_file(src_idx);
                        END IF;
                    ELSE
                        register_value_src_data_out <= (OTHERS => '0');
                    END IF;

                -- Write Operation (write_enable_in = '1')
                ELSIF write_enable_in = '1' THEN
                    reg_file(dest_idx) <= register_value_dest_data_in;
                    register_value_dest_data_out <= register_value_dest_data_in;
                END IF;
            ELSE
                register_value_dest_data_out <= (OTHERS => '0');
                register_value_src_data_out  <= (OTHERS => '0');
            END IF;
        END IF;
    END PROCESS;

END Behavioral;
