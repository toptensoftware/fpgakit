library ieee;
use IEEE.numeric_std.all;
use ieee.std_logic_1164.all;

entity TestBench is
end TestBench;

architecture behavior of TestBench is
    constant c_clock_hz : real := 10_000_000.0;
    signal s_clock : std_logic := '0';
    signal s_clken : std_logic := '0';
    signal s_reset : std_logic;
    signal s_signal : std_logic;
    signal s_delayed : std_logic;
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

    div : entity work.ClockDivider
    generic map
    (
        p_period => 10
    )
    port map
    ( 
        i_clock => s_clock,
        i_clken => '1',
        i_reset => s_reset,
        o_clken => s_clken
    );

    uut : entity work.DelayedSignal
    generic map
    (
        p_delay_period => 10
    )
    port map
    ( 
        i_clock => s_clock,
        i_clken => s_clken,
        i_reset => s_reset,
        i_signal => s_signal,
        o_signal => s_delayed
    );

    signal_driver : process
    begin
        s_signal <= '0';
        wait for 10 us;
        s_signal <= '1';
        wait for 30 us;
        s_signal <= '0';
        wait;
    end process;

end;