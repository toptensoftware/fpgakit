library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity top is
port 
( 
	i_clock_100mhz_unbuffered : in std_logic;
	i_button_b : in std_logic;
	o_leds : out std_logic_vector(7 downto 0);
	o_seven_segment : out std_logic_vector(7 downto 0);
	o_seven_segment_en : out std_logic_vector(2 downto 0);

	-- UART
	o_uart_tx : out std_logic;

	-- Folded memory controller bus
	mcb_xcl : out std_logic_vector(1 downto 0);
	mcb_xtx : out std_logic_vector(20 downto 0);
	mcb_xtr : inout  std_logic_vector(18 downto 0)

);
end top;

architecture Behavioral of top is

	-- Clocking
	signal s_reset : std_logic;
	signal s_clock_80mhz : std_logic;
	signal s_clock_100mhz : std_logic;
	signal s_clken_cpu : std_logic;

	-- MID Port
	signal mig_xtx : std_logic_vector(80 downto 0);
	signal mig_xrx : std_logic_vector(56 downto 0);

	-- Leds
	signal s_seven_seg_value: std_logic_vector(11 downto 0);

	-- Debug
	signal s_calib_done : std_logic;
	signal s_logic_capture : std_logic_vector(136 downto 0);

	signal mig_port_calib_done 						  : std_logic;
    signal mig_port_cmd_clk                           : std_logic;
    signal mig_port_cmd_en                            : std_logic;
    signal mig_port_cmd_instr                         : std_logic_vector(2 downto 0);
    signal mig_port_cmd_bl                            : std_logic_vector(5 downto 0);
    signal mig_port_cmd_byte_addr                     : std_logic_vector(29 downto 0);
    signal mig_port_cmd_empty                         : std_logic;
    signal mig_port_cmd_full                          : std_logic;
    signal mig_port_wr_clk                            : std_logic;
    signal mig_port_wr_en                             : std_logic;
    signal mig_port_wr_mask                           : std_logic_vector(3 downto 0);
    signal mig_port_wr_data                           : std_logic_vector(31 downto 0);
    signal mig_port_wr_full                           : std_logic;
    signal mig_port_wr_empty                          : std_logic;
    signal mig_port_wr_count                          : std_logic_vector(6 downto 0);
    signal mig_port_wr_underrun                       : std_logic;
    signal mig_port_wr_error                          : std_logic;
    signal mig_port_rd_clk                            : std_logic;
    signal mig_port_rd_en                             : std_logic;
    signal mig_port_rd_data                           : std_logic_vector(31 downto 0);
    signal mig_port_rd_full                           : std_logic;
    signal mig_port_rd_empty                          : std_logic;
    signal mig_port_rd_count                          : std_logic_vector(6 downto 0);
    signal mig_port_rd_overflow                       : std_logic;
    signal mig_port_rd_error                          : std_logic;

	signal s_state : integer range 0 to 15;

begin

	-- Logic Capture
	s_logic_capture <= 
		mig_port_cmd_clk &
		mig_port_cmd_en &
		mig_port_cmd_instr &
		mig_port_cmd_bl &
		mig_port_cmd_byte_addr &
		mig_port_cmd_empty &
		mig_port_cmd_full &
		mig_port_wr_clk &
		mig_port_wr_en &
		mig_port_wr_mask &
		mig_port_wr_data &
		mig_port_wr_full &
		mig_port_wr_empty &
		mig_port_wr_count &
		mig_port_wr_underrun &
		mig_port_wr_error &
		mig_port_rd_clk &
		mig_port_rd_en &
		mig_port_rd_data &
		mig_port_rd_full &
		mig_port_rd_empty &
		mig_port_rd_count &
		mig_port_rd_overflow &
		mig_port_rd_error
		;

	cap : entity work.LogicCapture
	generic map
	(
		p_clock_hz => 100_000_000,
		p_bit_width => 137,
		p_addr_width => 11
	)
	port map
	( 
		i_clock => s_clock_100mhz,
		i_clken => '1',
		i_reset => s_reset,
		i_trigger => s_calib_done,
		i_signals => s_logic_capture,
		o_uart_tx => o_uart_tx
	);

	-- Reset signal
	s_reset <= (not i_button_b);

	-- Debug
	s_seven_seg_value <= (others => '0');

	-- Clock Buffer
    clk_ibufg : IBUFG
    port map
    (
		I => i_clock_100mhz_unbuffered,
		O => s_clock_100mhz
	);

	 -- DCM
	dcm : entity work.ClockDCM
	port map
	(
		CLK_IN_100MHz => s_clock_100mhz,
		CLK_OUT_100MHz => open,
		CLK_OUT_80MHz => s_clock_80mhz
	);

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
		i_clock => s_clock_100mhz,
		i_reset => s_Reset,
		i_data => s_seven_seg_value,
		o_segments => o_seven_segment(7 downto 1),
		o_segments_en => o_seven_segment_en
	);
	o_seven_segment(0) <= '1';


	-- LPDDR Wrapper
	lpddr : entity work.MimasSinglePortSDRAM
	generic map
	(
		C3_INPUT_CLK_TYPE => "IBUFG"
	)
	port map
	(
		mcb_xtr => mcb_xtr,
		mcb_xtx => mcb_xtx,
		mcb_xcl => mcb_xcl,

		i_sys_clk       => s_clock_100mhz,
		i_sys_rst_n     => '0',
		o_calib_done    => s_calib_done,
		o_clk0          => open,
		o_rst0          => open,

		mig_xtx_p0 => mig_xtx,
		mig_xrx_p0 => mig_xrx
	);

	unfold_port : entity work.MigPort32Unfold
	port map
	( 
		mig_xrx => mig_xrx,
		mig_xtx => mig_xtx,
		mig_port_calib_done => mig_port_calib_done,
		mig_port_cmd_clk => mig_port_cmd_clk,
		mig_port_cmd_en => mig_port_cmd_en,
		mig_port_cmd_instr => mig_port_cmd_instr,
		mig_port_cmd_bl => mig_port_cmd_bl,
		mig_port_cmd_byte_addr => mig_port_cmd_byte_addr,
		mig_port_cmd_empty => mig_port_cmd_empty,
		mig_port_cmd_full => mig_port_cmd_full,
		mig_port_wr_clk => mig_port_wr_clk,
		mig_port_wr_en => mig_port_wr_en,
		mig_port_wr_mask => mig_port_wr_mask,
		mig_port_wr_data => mig_port_wr_data,
		mig_port_wr_full => mig_port_wr_full,
		mig_port_wr_empty => mig_port_wr_empty,
		mig_port_wr_count => mig_port_wr_count,
		mig_port_wr_underrun => mig_port_wr_underrun,
		mig_port_wr_error => mig_port_wr_error,
		mig_port_rd_clk => mig_port_rd_clk,
		mig_port_rd_en => mig_port_rd_en,
		mig_port_rd_data => mig_port_rd_data,
		mig_port_rd_full => mig_port_rd_full,
		mig_port_rd_empty => mig_port_rd_empty,
		mig_port_rd_count => mig_port_rd_count,
		mig_port_rd_overflow => mig_port_rd_overflow,
		mig_port_rd_error => mig_port_rd_error
	);

	mig_port_cmd_clk <= s_clock_100mhz;
	mig_port_cmd_bl <= (others => '0');
	mig_port_wr_clk <= s_clock_100mhz;
	mig_port_rd_clk <= s_clock_100mhz;
	

	traffic : process(s_clock_100mhz)
	begin
		if rising_edge(s_clock_100mhz) then
			if s_reset = '1' then
				s_state <= 0;
				mig_port_cmd_byte_addr <= (others => '0');
				mig_port_wr_data <= x"a1a2a3a4";
				mig_port_wr_mask <= "0000";
				mig_port_wr_en <= '0';
				mig_port_rd_en <= '0';
				mig_port_cmd_en <= '0';
				o_leds <= (others => '0');
			else

				mig_port_wr_en <= '0';	
				mig_port_rd_en <= '0';
				mig_port_cmd_en <= '0';

				case s_state is
					when 0 =>
						if mig_port_calib_done = '1' then
							s_state <= 1;
						end if;

					when 1 =>
						s_state <= 2;
						mig_port_wr_en <= '1';

					when 2 =>
						if mig_port_cmd_full = '0' then
							mig_port_cmd_instr <= "000";		-- write
							mig_port_cmd_en <= '1';
							s_state <= 6;
						end if;

					when 6 =>
						if mig_port_cmd_full = '0' then
							mig_port_cmd_instr <= "001";		-- read
							mig_port_cmd_en <= '1';
							s_state <= 7;
						end if;

					when 7 =>
						if mig_port_rd_empty = '0' then
							mig_port_rd_en <= '1';
							if mig_port_rd_data = mig_port_wr_data then
								mig_port_cmd_byte_addr <= std_logic_vector(unsigned(mig_port_cmd_byte_addr) + 1);
								mig_port_wr_data <= std_logic_vector(unsigned(mig_port_wr_data) + 1);
								s_state <= 1;
								o_leds(0) <= '1';
							else
								s_state <= 14;
								o_leds(1) <= '1';
							end if;
						end if;

					when others =>
						null;
				end case;

			end if;
		end if;
	end process;

end Behavioral;

