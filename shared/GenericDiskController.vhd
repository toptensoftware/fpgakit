--------------------------------------------------------------------------
--
-- SysConDiskController
--
-- Implements a the SysCon Disk Controller
-- 
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SysConDiskController is
port
(
	-- Clocking
	i_reset : in std_logic;
    i_clock : in std_logic;

	-- CPU connection
	i_cpu_port_number : in std_logic_vector(2 downto 0);
	i_cpu_port_wr_rising_edge : in std_logic;
	i_cpu_port_rd_falling_edge : in std_logic;
	o_cpu_din : out std_logic_vector(7 downto 0);
	i_cpu_dout : in std_logic_vector(7 downto 0);
	o_irq : out std_logic;

	-- SD Card Controller Connection
	i_sd_status : in std_logic_vector(7 downto 0);
	o_sd_op_write : out std_logic;
	o_sd_op_cmd : out std_logic_vector(1 downto 0);
	o_sd_op_block_number : out std_logic_vector(31 downto 0);
	i_sd_data_start : in std_logic;
	i_sd_data_cycle : in std_logic;
	o_sd_din : out std_logic_vector(7 downto 0);
	i_sd_dout : in std_logic_vector(7 downto 0)
);
end SysConDiskController;

architecture Behavioral of SysConDiskController is

	signal s_sd_op_block_number : std_logic_vector(31 downto 0);

	signal s_cpu_ram_addr : std_logic_vector(9 downto 0);
	signal s_cpu_ram_din : std_logic_vector(7 downto 0);
	signal s_cpu_ram_dout : std_logic_vector(7 downto 0);
	signal s_cpu_ram_write : std_logic;

	signal s_sd_ram_addr : std_logic_vector(9 downto 0);
	signal s_sd_ram_din : std_logic_vector(7 downto 0);
	signal s_sd_ram_dout : std_logic_vector(7 downto 0);
	signal s_sd_ram_write : std_logic;

begin

	-- Output the block number
	o_sd_op_block_number <= s_sd_op_block_number;

	-- Connect SD data interfaces to RAM
	o_sd_din <= s_sd_ram_dout;
	s_sd_ram_din <= i_sd_dout;

	-- Write to RAM when data cycle and when reading from SD Card
	s_sd_ram_write <= i_sd_data_cycle when i_sd_status(1)='1' else '0';

	-- Connect CPU data out to ram data in
	s_cpu_ram_din <= i_cpu_dout;

	-- And either status of ram out to CPU data in
	o_cpu_din <= s_cpu_ram_dout when i_cpu_port_number = "010" else i_sd_status;

	-- RAM Write from CPU?
	s_cpu_ram_write <= i_cpu_port_wr_rising_edge when i_cpu_port_number = "010" else '0';

	-- Generate IRQ whenever idle
	o_irq <= not i_sd_status(0);

	-- Handle block number writes
	load_block_number : process(i_clock)
	begin
		if rising_edge(i_clock) then
			if i_reset = '1' then
				s_sd_op_block_number <= x"00000000";
			else
				-- Write to port 0x90 shifts in block number
				if i_cpu_port_wr_rising_edge = '1' and i_cpu_port_number = "000" then
					s_sd_op_block_number <= i_cpu_dout & s_sd_op_block_number(31 downto 8);
				end if;
			end if;
		end if;
	end process;



	-- CPU Interface
	cpu_interface : process(i_clock)
	begin
		if rising_edge(i_clock) then
			if i_reset = '1' then
				o_sd_op_write <= '0';
				o_sd_op_cmd <= (others => '0');
				s_cpu_ram_addr <= (others => '0');
			else

				-- Clear pulses
				o_sd_op_write <= '0';

				-- Start a new command (write to port 0x91)
				if i_cpu_port_wr_rising_edge = '1' and i_cpu_port_number = "001" and i_sd_status(0) = '0' then
					o_sd_op_write <= '1';
					o_sd_op_cmd <= i_cpu_dout(1 downto 0);
					s_cpu_ram_addr <= (others => '0');
				end if;


				-- Write data (0x92)
				if i_cpu_port_wr_rising_edge = '1' and i_cpu_port_number = "010" then
					s_cpu_ram_addr <= std_logic_vector(unsigned(s_cpu_ram_addr) + 1);
				end if;

				-- Read data (0x92)
				if i_cpu_port_rd_falling_edge = '1' and i_cpu_port_number = "010" then
					s_cpu_ram_addr <= std_logic_vector(unsigned(s_cpu_ram_addr) + 1);
				end if;

			end if;
		end if;
	end process;



	-- SD Side Interface
	sd_interface : process(i_clock)
	begin
		if rising_edge(i_clock) then
			if i_reset = '1' then
				s_sd_ram_addr <= (others => '0');
			else
				if i_sd_data_start = '1' then
					s_sd_ram_addr <= (others => '0');
				elsif i_sd_data_cycle = '1' then
					s_sd_ram_addr <= std_logic_vector(unsigned(s_sd_ram_addr) + 1);
				end if;
			end if;
		end if;
	end process;	



	-- Sector RAM (512 bytes)
	ram : entity work.RamDualPortInferred
	generic map
	(
		p_addr_width => 10,
		p_data_width => 8
	)
	port map
	(
		i_clock_a => i_clock,
		i_clken_a => '1',
		i_addr_a => s_cpu_ram_addr,
		i_din_a => s_cpu_ram_din,
		o_dout_a => s_cpu_ram_dout,
		i_write_a => s_cpu_ram_write,

		i_clock_b => i_clock,
		i_clken_b => '1',
		i_addr_b => s_sd_ram_addr,
		i_din_b => s_sd_ram_din,
		o_dout_b => s_sd_ram_dout,
		i_write_b => s_sd_ram_write
	);

end Behavioral;

