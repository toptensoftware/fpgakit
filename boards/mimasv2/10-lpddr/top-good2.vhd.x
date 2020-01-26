library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity top is
port 
( 
	-- These signals must match what's in the .ucf file
	i_clock_100mhz : in std_logic;
	c3_sys_rst_n : in std_logic;
	i_button_b : in std_logic;
	o_leds : out std_logic_vector(7 downto 0);
	o_seven_segment : out std_logic_vector(7 downto 0);
	o_seven_segment_en : out std_logic_vector(2 downto 0);

	-- Collapsed memory controller bus
	io_mcb : inout  std_logic_vector(18 downto 0);
	o_mcb : out std_logic_vector(20 downto 0);
	cl_mcb : out std_logic_vector(1 downto 0)
);
end top;

architecture Behavioral of top is
	signal s_reset : std_logic;
	signal s_clock : std_logic;
	signal debug_hex: std_logic_vector(11 downto 0);
	signal debug_hi : std_logic_vector(3 downto 0);
	signal debug_byte : std_logic_vector(7 downto 0);

	signal c3_calib_done : std_logic;

    signal s_mcb_cmd_instr : std_logic_vector(2 downto 0);
    signal s_mcb_cmd_en : std_logic;
	signal s_mcb_cmd_byte_addr : std_logic_vector(29 downto 0); 
	signal s_mcb_cmd_empty : std_logic;
	signal s_mcb_cmd_full : std_logic;
    signal s_mcb_wr_en : std_logic;
    signal s_mcb_wr_mask : std_logic_vector(3 downto 0);
    signal s_mcb_wr_data : std_logic_vector(31 downto 0);
    signal s_mcb_wr_empty : std_logic;
    signal s_mcb_rd_en : std_logic;
	signal s_mcb_rd_data : std_logic_vector(31 downto 0);
	signal s_mcb_rd_empty : std_logic;

	signal s_error : std_logic;

	signal debug : std_logic_vector(7 downto 0);

	signal s_state_traf : integer range 0 to 15 := 0;

	signal s_sri_wr : std_logic;
	signal s_sri_rd : std_logic;
	signal s_sri_wait : std_logic;
    signal s_sri_addr : std_logic_vector(29 downto 0);
    signal s_sri_dout : std_logic_vector(7 downto 0);
    signal s_sri_din : std_logic_vector(7 downto 0);

	begin

	-- Reset signal
	s_reset <= (not i_button_b);

	-- Debug LEDs
	o_leds <= debug;

	-- Clock Buffer
    clk_ibufg : IBUFG
    port map
    (
		I => i_clock_100mhz,
		O => s_clock
	);

	 -- DCM
--	dcm : entity work.ClockDCM
--	port map
--	(
--		CLK_IN_100MHz => s_CLK_100MHz_buffered,
--		CLK_OUT_100MHz => open,
--		CLK_OUT_80MHz => s_clock_80mhz
--	);

	-- Clock divider
--	clock_divider : entity work.ClockDivider
--	generic map
--	(
--		p_period => 45
--	)
--	port map
--	(
--		i_clock => s_clock_80mhz,
--		i_clken => '1',
--		i_reset => s_reset,
--		o_clken => s_clken_cpu
--	);

	-- Seven segment display
	seven_seg : entity work.SevenSegmentHexDisplayWithClockDivider
	generic map
	(
		p_clock_hz => 100_000_000
	)
	port map
	( 
		i_clock => s_clock,
		i_reset => s_Reset,
		i_data => debug_hex,
		o_segments => o_seven_segment(7 downto 1),
		o_segments_en => o_seven_segment_en
	);
	o_seven_segment(0) <= '1';


	-- LPDDR Wrapper
	lpddr : entity work.MimasDualPortSDRAM
	generic map
	(
		C3_INPUT_CLK_TYPE => "IBUFG"
	)
	port map
	(
		mcb3_dram_dq     => io_mcb(15 downto 0),
		mcb3_dram_udqs   => io_mcb(16),
		mcb3_rzq         => io_mcb(18),
		mcb3_dram_a      => o_mcb(12 downto 0),
		mcb3_dram_ba     => o_mcb(14 downto 13),
		mcb3_dram_cke    => o_mcb(15),
		mcb3_dram_ras_n  => o_mcb(16),
		mcb3_dram_cas_n  => o_mcb(17),
		mcb3_dram_we_n   => o_mcb(18),
		mcb3_dram_dm     => o_mcb(19),
		mcb3_dram_udm    => o_mcb(20),
		mcb3_dram_dqs    => io_mcb(17),
		mcb3_dram_ck     => cl_mcb(0),
		mcb3_dram_ck_n   => cl_mcb(1),

		c3_sys_clk       => s_clock,
		c3_sys_rst_n     => c3_sys_rst_n,
		c3_calib_done    => c3_calib_done,
		c3_clk0          => open,
		c3_rst0          => open,

		c3_p0_cmd_clk => s_clock,
		c3_p0_cmd_en => s_mcb_cmd_en,
		c3_p0_cmd_instr => s_mcb_cmd_instr,
		c3_p0_cmd_bl => "000000",
		c3_p0_cmd_byte_addr => s_mcb_cmd_byte_addr,
		c3_p0_cmd_empty => s_mcb_cmd_empty,
		c3_p0_cmd_full => s_mcb_cmd_full,
		c3_p0_wr_clk => s_clock,
		c3_p0_wr_en => s_mcb_wr_en,
		c3_p0_wr_mask => s_mcb_wr_mask,
		c3_p0_wr_data => s_mcb_wr_data,
		c3_p0_wr_full => open,
		c3_p0_wr_empty => s_mcb_wr_empty,
		c3_p0_wr_count => open,
		c3_p0_wr_underrun => open,
		c3_p0_wr_error => open,
		c3_p0_rd_clk => s_clock,
		c3_p0_rd_en => s_mcb_rd_en,
		c3_p0_rd_data => s_mcb_rd_data,
		c3_p0_rd_full => open,
		c3_p0_rd_empty => s_mcb_rd_empty,
		c3_p0_rd_count => open,
		c3_p0_rd_overflow => open,
		c3_p0_rd_error => open,

		c3_p1_cmd_clk => s_clock,
		c3_p1_cmd_en => '0',
		c3_p1_cmd_instr => (others => '0'),
		c3_p1_cmd_bl => (others => '0'),
		c3_p1_cmd_byte_addr => (others => '0'),
		c3_p1_cmd_empty => open,
		c3_p1_cmd_full => open,		
		c3_p1_wr_clk => s_clock,
		c3_p1_wr_en => '0',
		c3_p1_wr_mask => (others => '0'),
		c3_p1_wr_data => (others => '0'),
		c3_p1_wr_full => open,
		c3_p1_wr_empty => open,
		c3_p1_wr_count => open,
		c3_p1_wr_underrun => open,
		c3_p1_wr_error => open,		
		c3_p1_rd_clk => s_clock,
		c3_p1_rd_en => '0',
		c3_p1_rd_data => open,
		c3_p1_rd_full => open,
		c3_p1_rd_empty => open,
		c3_p1_rd_count => open,
		c3_p1_rd_overflow => open,
		c3_p1_rd_error => open
	);


	debug_hex <= debug_hi & debug_byte;

	sri : entity work.SimpleRamInterfaceUnfolded
	port map
	( 
		i_clock => s_clock,
		i_clken => '1',
		i_reset => s_reset,
		i_rd => s_sri_rd,
		i_wr => s_sri_wr,
		i_addr => s_sri_addr,
		i_data => s_sri_din,
		o_data => s_sri_dout,
		o_wait => s_sri_wait,
		mcb_calib_done => c3_calib_done,
		mcb_cmd_instr => s_mcb_cmd_instr,
		mcb_cmd_en => s_mcb_cmd_en,
		mcb_cmd_byte_addr => s_mcb_cmd_byte_addr,
		mcb_cmd_empty => s_mcb_cmd_empty,
		mcb_cmd_full => s_mcb_cmd_full,
		mcb_wr_en => s_mcb_wr_en,
		mcb_wr_mask => s_mcb_wr_mask,
		mcb_wr_data => s_mcb_wr_data,
		mcb_wr_empty => s_mcb_wr_empty,
		mcb_rd_en => s_mcb_rd_en,
		mcb_rd_data => s_mcb_rd_data,
		mcb_rd_empty => s_mcb_rd_empty
	);


	traffic : process(s_clock)
	begin
		if rising_edge(s_clock) then
			if s_reset = '1' then
				s_sri_din <= (others => '0');
				s_sri_addr <= (others => '0');
				s_sri_rd <= '0';
				s_sri_wr <= '0';
				s_state_traf <= 0;
				debug <= (others => '0');
				debug_byte <= (others => '0');
				debug_hi <= (others => '0');
			else

				s_sri_rd <= '0';	
				s_sri_wr <= '0';

				case s_state_traf is
					when 0 =>
						s_sri_addr <= "00" & x"0000001";
						s_sri_din <= x"23";
						s_sri_wr <= '1';
						s_state_traf <= 1;

					when 1 =>
						s_state_traf <= 2;

					when 2 =>
						if s_sri_wait = '0' then
							s_sri_rd <= '1';
							s_state_traf <= 3;
						end if;

					when 3 =>
						s_state_traf <= 4;

					when 4 =>
						if s_sri_wait = '0' then
							s_state_traf <= 5;
						end if;

					when others =>
						if s_sri_dout = x"23" then
							debug(7) <= '1';
						else
							debug(6) <= '1';
						end if;
						debug_byte <= s_sri_dout;

				end case;

			end if;
		end if;
	end process;

end Behavioral;

