
# Entity: registerfile 
- **File**: registerfile.vhd
- **Brief:**  Register File (16 Registers x 8 bits each)
- **Details:**  Supports dual-read ports (destination & source) and synchronous write back.

## Diagram
![Diagram](registerfile.svg "Diagram")
## Description

Provides optional two's complement transformation on the source register read path.

## Ports

| Port name                    | Direction | Type                          | Description                                                           |
| ---------------------------- | --------- | ----------------------------- | --------------------------------------------------------------------- |
| cpu_clk                      | in        | STD_LOGIC                     | Master CPU clock input                                                |
| cpu_enable                   | in        | STD_LOGIC                     | Global CPU enable signal (active high)                                |
| write_enable_in              | in        | STD_LOGIC                     | Write enable control ('1' = Write, '0' = Read)                        |
| address_flag                 | in        | STD_LOGIC                     | Address mode flag ('1' = Source register valid, '0' = Immediate mode) |
| negative_flag                | in        | STD_LOGIC                     | Negative flag enable for two's complement writeback                   |
| register_addr_dest_data_in   | in        | STD_LOGIC_VECTOR (3 DOWNTO 0) | 4-bit destination register address input                              |
| register_addr_src_data_in    | in        | STD_LOGIC_VECTOR (3 DOWNTO 0) | 4-bit source register address input                                   |
| register_value_dest_data_in  | in        | STD_LOGIC_VECTOR (7 DOWNTO 0) | 8-bit data input to write into destination register                   |
| register_value_src_data_in   | in        | STD_LOGIC_VECTOR (7 DOWNTO 0) | 8-bit secondary data input                                            |
| register_value_dest_data_out | out       | STD_LOGIC_VECTOR (7 DOWNTO 0) | 8-bit data output read from destination register                      |
| register_value_src_data_out  | out       | STD_LOGIC_VECTOR (7 DOWNTO 0) | 8-bit data output read from source register                           |

## Signals

| Name     | Type      | Description                                 |
| -------- | --------- | ------------------------------------------- |
| reg_file | reg_array | Internal register array storage (R0 to R15) |

## Types

| Name      | Type | Description                                          |
| --------- | ---- | ---------------------------------------------------- |
| reg_array |      | 16-element array of 8-bit std_logic_vector registers |

## Processes
- reg_process: ( cpu_clk )
  - **Description**
  Synchronous register file read and write access process
