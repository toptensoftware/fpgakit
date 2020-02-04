library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity TestBench is
end TestBench;

architecture behavior of TestBench is
    constant c_clock_hz : real := 100_000_000.0;
    signal s_clock : std_logic := '0';
    signal s_reset : std_logic;
    signal s_uart_traffic_tx : std_logic;
    signal s_uart_empty : std_logic;
    signal s_uart_read : std_logic;
    signal s_uart_dout : std_logic_vector(7 downto 0);
    signal s_clken_reader : std_logic;
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

    uart : entity work.UartRxBuffered
    generic map
    (
        p_clock_hz => integer(c_clock_hz),
        p_baud => 115200,
        p_addr_width => 3
    )
    port map
    (
        i_clock => s_clock,
        i_reset => s_reset,
        i_uart_rx => s_uart_traffic_tx,
        i_read => s_uart_read,
        o_dout => s_uart_dout,
        o_busy => open,
        o_full => open,
        o_empty => s_uart_empty,
        o_underflow => open,
        o_overflow => open,
        o_count => open
    );

    traffic : entity work.UartTxTest
    generic map
    (
        p_clock_hz => integer(c_clock_hz),
        p_bytes_per_chunk => 4,
        p_chunks_per_second => 10,
        p_baud => 115200
    )
    port map
    ( 
        i_clock => s_clock,
        i_reset => s_reset,
        o_uart_tx => s_uart_traffic_tx
    );

    div : entity work.ClockDivider
    generic map
    (
        p_period => 25_000
    )
    port map
    ( 
        i_clock => s_clock,
        i_clken => '1',
        i_reset => s_reset,
        o_clken => s_clken_reader
    );


    reader : process(s_clock)
    begin
        if rising_edge(s_clock) then
            if s_reset = '1' then
                s_uart_read <= '0';
            else
                s_uart_read <= '0';
                if s_clken_reader = '1' and s_uart_empty = '0' then
                    s_uart_read <= '1';
                end if;
            end if;
        end if;
    end process;

end;