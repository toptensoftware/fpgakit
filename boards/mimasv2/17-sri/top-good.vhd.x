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

	-- Memory controller
	mcb3_dram_dq    : inout  std_logic_vector(15 downto 0);
	mcb3_dram_a     : out std_logic_vector(12 downto 0);
	mcb3_dram_ba    : out std_logic_vector(1 downto 0);
	mcb3_dram_cke   : out std_logic;
	mcb3_dram_ras_n : out std_logic;
	mcb3_dram_cas_n : out std_logic;
	mcb3_dram_we_n  : out std_logic;
	mcb3_dram_dm    : out std_logic;
	mcb3_dram_udqs  : inout std_logic;
	mcb3_rzq        : inout std_logic;
	mcb3_dram_udm   : out std_logic;
	mcb3_dram_dqs   : inout std_logic;
	mcb3_dram_ck    : out std_logic;
	mcb3_dram_ck_n  : out std_logic
);
end top;

architecture Behavioral of top is
	signal s_reset : std_logic;
	signal s_clock : std_logic;
	signal debug_hex: std_logic_vector(11 downto 0);
	signal debug1 : std_logic_vector(3 downto 0);
	signal debug2 : std_logic_vector(3 downto 0);
	signal debug3 : std_logic_vector(3 downto 0);

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

	signal s_good : std_logic;
	signal s_error : std_logic;

	signal debug : std_logic_vector(7 downto 0);

	signal s_state : integer range 0 to 15;
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
	--xilt:require:./coregen/mimas_lpddr/user_design/rtl/mimas_lpddr.vhd
	--xilt:require:./coregen/mimas_lpddr/user_design/rtl/memc3_infrastructure.vhd
	--xilt:require:./coregen/mimas_lpddr/user_design/rtl/memc3_wrapper.vhd
	--xilt:require:./coregen/mimas_lpddr/user_design/rtl/mcb_raw_wrapper.vhd
	--xilt:require:./coregen/mimas_lpddr/user_design/rtl/mcb_soft_calibration_top.vhd
	--xilt:require:./coregen/mimas_lpddr/user_design/rtl/mcb_soft_calibration.vhd
	--xilt:require:./coregen/mimas_lpddr/user_design/rtl/iodrp_controller.vhd
	--xilt:require:./coregen/mimas_lpddr/user_design/rtl/iodrp_mcb_controller.vhd
	--xilt:nowarn:coregen/mimas_lpddr
	lpddr : entity work.mimas_lpddr
	generic map
	(
		C3_INPUT_CLK_TYPE => "IBUFG"
	)
	port map
	(
		mcb3_dram_dq     => mcb3_dram_dq,
		mcb3_dram_a      => mcb3_dram_a,
		mcb3_dram_ba     => mcb3_dram_ba,
		mcb3_dram_cke    => mcb3_dram_cke,
		mcb3_dram_ras_n  => mcb3_dram_ras_n,
		mcb3_dram_cas_n  => mcb3_dram_cas_n,
		mcb3_dram_we_n   => mcb3_dram_we_n,
		mcb3_dram_dm     => mcb3_dram_dm,
		mcb3_dram_udqs   => mcb3_dram_udqs,
		mcb3_rzq         => mcb3_rzq,
		mcb3_dram_udm    => mcb3_dram_udm,
		mcb3_dram_dqs    => mcb3_dram_dqs,
		mcb3_dram_ck     => mcb3_dram_ck,
		mcb3_dram_ck_n   => mcb3_dram_ck_n,

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

	debug_hex <= debug1 & debug2 & debug3;

	debug3 <= std_logic_vector(to_unsigned(s_state, 4));


	traffic : process(s_clock)
	begin
		if rising_edge(s_clock) then
			if s_reset = '1' then
				s_state <= 0;
				s_mcb_cmd_byte_addr <= (others => '0');
				s_mcb_wr_data <= x"a1a2a3a4";
				s_mcb_wr_mask <= "0000";
				s_mcb_wr_en <= '0';
				s_mcb_rd_en <= '0';
				s_mcb_cmd_en <= '0';
				debug1 <= x"C";
				debug2 <= x"C";
				debug <= (others => '0');
			else

				s_mcb_wr_en <= '0';	
				s_mcb_rd_en <= '0';
				s_mcb_cmd_en <= '0';

				case s_state is
					when 0 =>
						if c3_calib_done = '1' then
							s_state <= 1;
						end if;

					when 1 =>
						s_state <= 2;
						s_mcb_wr_en <= '1';

					when 2 =>
						if s_mcb_cmd_full = '0' then
							s_mcb_cmd_instr <= "000";		-- write
							s_mcb_cmd_en <= '1';
							s_state <= 6;
						end if;

					when 6 =>
						if s_mcb_cmd_full = '0' then
							s_mcb_cmd_instr <= "001";		-- read
							s_mcb_cmd_en <= '1';
							s_state <= 7;
						end if;

					when 7 =>
						if s_mcb_rd_empty = '0' then
							if s_mcb_rd_data = x"a1a2a3a4" then
								debug(0) <= '1';
								s_state <= 15;
							else
								debug(1) <= '1';
								s_state <= 14;
							end if;
						end if;

					when others =>
						null;
				end case;

			end if;
		end if;
	end process;
end Behavioral;

