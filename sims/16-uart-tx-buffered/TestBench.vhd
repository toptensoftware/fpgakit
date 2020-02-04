library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity TestBench is
end TestBench;

architecture behavior of TestBench is
    signal s_clock : std_logic := '0';
    signal s_reset : std_logic;
    signal s_clken : std_logic;
    signal s_uart_din : std_logic_vector(7 downto 0);
    signal s_uart_write : std_logic;
    constant c_clock_hz : real := 100_000_000.0;
    signal s_state : integer range 0 to 31;
begin


    reset_proc: process
    begin
        s_reset <= '1';
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

    uart : entity work.UartTxBuffered
    generic map
    (
        p_clken_hz => integer(c_clock_hz),
        p_baud => 115200,
        p_addr_width => 3
    )
    port map
    (
        i_clock => s_clock,
        i_clken => '1',
        i_reset => s_reset,
        i_write => s_uart_write,
        i_din => s_uart_din,
        o_uart_tx => open,
        o_busy => open,
        o_full => open,
        o_empty => open,
        o_underflow => open,
        o_overflow => open,
        o_count => open
    );

    traffic : process(s_clock)
    begin
        if rising_edge(s_clock) then
            if s_reset = '1' then
                s_state <= 0;
                s_uart_write <= '0';
                s_uart_din <= (others => '0');
            else
                if s_state < 31 then
                    s_state <= s_state + 1;
                end if;

                s_uart_write <= '0';

                case s_state is
                    when 1 => 
                        s_uart_write <= '1';
                        s_uart_din <= x"A6";

                    when 2 => 
                        s_uart_write <= '1';
                        s_uart_din <= x"00";

                    when 3 => 
                        s_uart_write <= '1';
                        s_uart_din <= x"FF";

                    when 4 => 
                        s_uart_write <= '1';
                        s_uart_din <= x"A5";

                    when 30 => 
                        s_uart_write <= '1';
                        s_uart_din <= x"30";

                    when others =>
                        null;
                end case;

            end if;
        end if;
    end process;

end;