library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

entity TestBench is
end TestBench;

architecture behavior of TestBench is
    constant c_clock_hz : real := 80_000_000.0;

    signal s_reset : std_logic;
    signal s_clock : std_logic := '0';
	signal s_clken : std_logic;

	-- ROM
	signal s_is_rom_range : std_logic;
	signal s_rom_addr : std_logic_vector(9 downto 0);
	signal s_rom_dout : std_logic_vector(15 downto 0);

	-- RAM
	signal s_is_ram_range : std_logic;
	signal s_ram_addr : std_logic_vector(12 downto 0);
	signal s_ram_din : std_logic_vector(15 downto 0);
	signal s_ram_dout : std_logic_vector(15 downto 0);
	signal s_ram_wr : std_logic;
	signal s_ram_wr_mask : std_logic_vector(1 downto 0);

	-- IO
	signal s_is_io_range : std_logic;
	signal s_io_addr : std_logic_vector(3 downto 0);
	signal s_io_din : std_logic_vector(15 downto 0);
	signal s_io_dout : std_logic_vector(15 downto 0);
	signal s_io_wr : std_logic;
	signal s_io_wr_mask : std_logic_vector(1 downto 0);

	-- CPU
	signal s_cpu_wr : std_logic;
	signal s_cpu_rd : std_logic;
	signal s_cpu_wr_mask : std_logic_vector(1 downto 0);
	signal s_cpu_wait : std_logic;
    signal s_cpu_addr : std_logic_vector(31 downto 0);
    signal s_cpu_dout : std_logic_vector(15 downto 0);
    signal s_cpu_din : std_logic_vector(15 downto 0);

	constant c_big_endian : std_logic := '1';

begin

    reset_proc: process
    begin
        s_reset <= '1';
        wait until falling_edge(s_clock);
        wait until rising_edge(s_clock);
        wait until falling_edge(s_clock);
        s_reset <= '0';
        wait;
    end process;

    stim_proc: process
    begin
        s_clock <= not s_clock;
        wait for 1 sec / (c_clock_hz * 2.0);
    end process;

	-- Clock divider
	clock_divider : entity work.ClockDivider
	generic map
	(
		p_period => 2
	)
	port map
	(
		i_clock => s_clock,
		i_clken => '1',
		i_reset => s_reset,
		o_clken => s_clken
	);


	rom : entity work.FirmwareRom
	port map
	(
		i_clock => s_clock,
		i_addr => s_rom_addr,
		o_dout => s_rom_dout
	);

	ram : entity work.RamInferred
	generic map
	(
		p_addr_width => 13,			-- 2^13 = 8192 words = 16K
		p_data_width => 16
	)
	port map
	(
		i_clock => s_clock,
		i_clken => s_clken,
		i_addr => s_ram_addr,
		i_data => s_ram_din,
		o_data => s_ram_dout,
		i_write => s_ram_wr,
		i_write_mask => s_ram_wr_mask
	);

	-- ROM Addressing
	s_is_rom_range <= '1' when s_cpu_addr(31 downto 16) = x"0010" else '0';
	s_rom_addr <= s_cpu_addr(10 downto 1);
	
	-- RAM Addressing
	s_is_ram_range <= '1' when s_cpu_addr(31 downto 16) = x"0020" else '0';
	s_ram_addr <= s_cpu_addr(13 downto 1);
	s_ram_din <= s_cpu_dout;
	s_ram_wr <= s_cpu_wr and s_is_ram_range;

	be_mask : if c_big_endian = '1' generate
		s_ram_wr_mask <= s_cpu_wr_mask(0) & s_cpu_wr_mask(1);
	end generate;

	le_mask : if c_big_endian = '1' generate
		s_ram_wr_mask <= s_cpu_wr_mask;
	end generate;

	-- IO Addressing
	s_is_io_range <= '1' when s_cpu_addr(31 downto 16) = x"8000" else '0';
	s_io_addr <= s_cpu_addr(3 downto 0);
	s_io_din <= s_cpu_dout;
	s_io_wr <= s_cpu_wr and s_is_io_range;
	s_io_wr_mask <= s_cpu_wr_mask;

	-- Multiplex CPU input
	s_cpu_wait <= '0';
	s_cpu_din <= 
		s_rom_dout when s_is_rom_range = '1' else
		s_ram_dout when s_is_ram_range = '1' else
		s_io_dout when s_is_io_range = '1' else
		(others => '1');

	-- CPU
	cpu : entity work.moxielite
	generic map
	(
		p_boot_address => x"00100000",
		p_big_endian => c_big_endian
	)
	port map
	(
		i_reset => s_reset,
		i_clock => s_clock,
		i_clken => s_clken,
		i_wait => s_cpu_wait,
		o_addr => s_cpu_addr,
		i_din => s_cpu_din,
		o_dout => s_cpu_dout,
		o_rd => s_cpu_rd,
		o_wr => s_cpu_wr,
		o_wr_mask => s_cpu_wr_mask,
		o_debug => open,
		i_gdb => (others => '0'),
		i_irq => '0',
		i_buserr => '0'
	);

end behavior;

