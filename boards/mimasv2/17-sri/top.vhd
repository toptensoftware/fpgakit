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
	signal mig_xtx_p0 : std_logic_vector(80 downto 0);
	signal mig_xrx_p0 : std_logic_vector(56 downto 0);

	-- Leds
	signal s_seven_seg_value: std_logic_vector(11 downto 0);
	signal debug : std_logic_vector(7 downto 0);

	-- Traffic generator
	signal s_state : integer range 0 to 15 := 0;
	signal s_sri_wr : std_logic;
	signal s_sri_rd : std_logic;
	signal s_sri_wait : std_logic;
    signal s_sri_addr : std_logic_vector(29 downto 0);
    signal s_sri_dout : std_logic_vector(7 downto 0);
    signal s_sri_din : std_logic_vector(7 downto 0);

	-- Debug
	signal s_calib_done : std_logic;
	signal s_logic_capture : std_logic_vector(48 downto 0);

begin

	-- Logic Capture
	s_logic_capture <= 
		s_sri_wr & s_sri_rd & s_sri_wait & 
		s_sri_addr & s_sri_dout & s_sri_din
		;

	cap : entity work.LogicCapture
	generic map
	(
		p_clock_hz => 80_000_000,
		p_bit_width => 49,
		p_addr_width => 13
	)
	port map
	( 
		i_clock => s_clock_80mhz,
		i_clken => '1',
		i_reset => s_reset,
		i_trigger => s_calib_done,
		i_signals => s_logic_capture,
		o_uart_tx => o_uart_tx
	);

	-- Reset signal
	s_reset <= (not i_button_b);

	-- Debug LEDs
	o_leds <= debug;

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
	clock_divider : entity work.ClockDivider
	generic map
	(
		p_period => 45
	)
	port map
	(
		i_clock => s_clock_80mhz,
		i_clken => '1',
		i_reset => s_reset,
		o_clken => s_clken_cpu
	);

	-- Seven segment display
	seven_seg : entity work.SevenSegmentHexDisplayWithClockDivider
	generic map
	(
		p_clock_hz => 80_000_000
	)
	port map
	( 
		i_clock => s_clock_80mhz,
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

		mig_xtx_p0 => mig_xtx_p0,
		mig_xrx_p0 => mig_xrx_p0
	);

	sri : entity work.SimpleRamInterface
	port map
	( 
		i_clock => s_clock_80mhz,
		i_clken => s_clken_cpu,
		i_reset => s_reset,
		i_rd => s_sri_rd,
		i_wr => s_sri_wr,
		i_addr => s_sri_addr,
		i_data => s_sri_din,
		o_data => s_sri_dout,
		o_wait => s_sri_wait,
		mig_xtx => mig_xtx_p0,
		mig_xrx => mig_xrx_p0
	);

	s_seven_seg_value <= s_sri_addr(11 downto 0);

	traffic : process(s_clock_80mhz)
	begin
		if rising_edge(s_clock_80mhz) then
			if s_reset = '1' then
				s_sri_din <= (others => '0');
				s_sri_addr <= (others => '0');
				s_sri_rd <= '0';
				s_sri_wr <= '0';
				s_state <= 0;
				debug <= (others => '0');
			elsif s_clken_cpu = '1' then

				s_sri_rd <= '0';	
				s_sri_wr <= '0';

				case s_state is
					when 0 =>
						s_sri_wr <= '1';
						s_state <= 1;
						debug <= "00000001";

					when 1 =>
						s_sri_rd <= '1';
						s_state <= 2;

					when 2 =>
						if s_sri_wait = '0' then
							s_sri_din <= std_logic_vector(unsigned(s_sri_din) + 1);
							if s_sri_din = x"ff" then
								s_sri_addr(7 downto 0) <= (others => '0');
								s_state <= 8;
							else
								s_sri_addr <= std_logic_vector(unsigned(s_sri_addr) + 1);
								s_state <= 0;
							end if;
						end if;

					when 8 =>
						s_sri_rd <= '1';
						s_state <= 9;
						debug <= "00000010";

					when 9 =>
						s_state <= 10;

					when 10 =>
						if s_sri_wait = '0' then
							if (s_sri_dout /= s_sri_din) then	
								s_state <= 14;
							else
							 	s_sri_din <= std_logic_vector(unsigned(s_sri_din) + 1);
								s_sri_addr <= std_logic_vector(unsigned(s_sri_addr) + 1);
								if s_sri_din = x"ff" then
									s_state <= 0;
								else
									s_state <= 8;
								end if;
							end if;
						end if;

					when 14 => 
						debug <= "11111111";

					when others =>
						null;

				end case;

			end if;
		end if;
	end process;

end Behavioral;

