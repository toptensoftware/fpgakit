library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

entity top is
port 
( 
	i_clock_100mhz : in std_logic;
	i_button_b : in std_logic;
	o_uart_tx : out std_logic;
	o_leds : out std_logic_vector(7 downto 0)
);
end top;

architecture Behavioral of top is
	signal s_reset : std_logic;
    signal s_fifo_write : std_logic;
    signal s_fifo_din : std_logic_vector(7 downto 0);
    signal s_fifo_read : std_logic;
    signal s_fifo_dout : std_logic_vector(7 downto 0);
    signal s_fifo_full : std_logic;
    signal s_fifo_empty : std_logic;
    signal s_fifo_underflow : std_logic;
    signal s_fifo_overflow : std_logic;
    signal s_fifo_count : std_logic_vector(3 downto 0);
	signal s_state_writer : integer range 0 to 31;
	signal s_clken_1second : std_logic;
	signal s_logic_capture : std_logic_vector(25 downto 0);
begin

	-- Reset signal
	s_reset <= not i_button_b;


	s_logic_capture <= 
		s_fifo_write &
		s_fifo_din &
		s_fifo_read &
		s_fifo_dout &
		s_fifo_full &
		s_fifo_empty &
		s_fifo_underflow &
		s_fifo_overflow &
		s_fifo_count;

	cap : entity work.LogicCapture
	generic map
	(
		p_clock_hz => 100_000_000,
		p_baud => 115_200,
		p_bit_width => 26,
		p_addr_width => 12
	)
	port map
	( 
		i_clock => i_clock_100mhz,
		i_clken => '1',
		i_reset => s_reset,
		i_trigger => '1',
		i_signals => s_logic_capture,
		o_uart_tx => o_uart_tx
	);

	fifo : entity work.Fifo
	generic map
	(
		p_bit_width => 8,
		p_addr_width => 4
	)
	port map
	( 
		i_clock => i_clock_100mhz,
		i_reset => s_reset,
		i_write => s_fifo_write,
		i_din => s_fifo_din,
		i_read => s_fifo_read,
		o_dout => s_fifo_dout,
		o_full => s_fifo_full,
		o_empty => s_fifo_empty,
		o_underflow => s_fifo_underflow,
		o_overflow => s_fifo_overflow,
		o_count => s_fifo_count
	);

	writer : process(i_clock_100mhz)
	begin
		if rising_edge(i_clock_100mhz) then
			if s_reset = '1' then
				s_state_writer <= 0;
			else
				if s_state_writer < 31 then
					s_state_writer <= s_state_writer + 1;
				end if;

				s_fifo_write <= '0';

				case s_state_writer is

					when 1 => 
						s_fifo_din <= x"AA";
						s_fifo_write <= '1';

					when 2 => 
						s_fifo_din <= x"BB";
						s_fifo_write <= '1';

					when 3 => 
						s_fifo_din <= x"CC";
						s_fifo_write <= '1';

					when 4 => 
						s_fifo_din <= x"DD";
						s_fifo_write <= '1';

					when others =>
						null;

				end case;
			end if;	
		end if;
	end process;

	div : entity work.ClockDivider
	generic map
	(
		p_period => 100_000_000
	)
	port map
	( 
		i_clock => i_clock_100mhz,
		i_clken => '1',
		i_reset => s_reset,
		o_clken => s_clken_1second
	);

	reader : process(i_clock_100mhz)
	begin
		if rising_edge(i_clock_100mhz) then
			if s_reset = '1' then
				o_leds <= (others => '1');
				s_fifo_read <= '0';
			else 
				s_fifo_read <= '0';
				if s_fifo_empty = '0' and s_clken_1second = '1' then
					o_leds <= s_fifo_dout;
					s_fifo_read <= '1';
				end if;
			end if;	
		end if;
	end process;

end Behavioral;

--xilt:nowarn:fifo/Mram_ram1_RAMD_D1_O
--xilt:nowarn:WARNING:Par:283 - There are 1 loadless
--xilt:nowarn:WARNING:PhysDesignRules:367
