library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity TestBench is
end TestBench;

architecture behavior of TestBench is
    signal s_clock : std_logic := '0';
    signal s_reset : std_logic;
    signal s_clock_enable_1 : std_logic;
    signal s_clock_enable_2 : std_logic;
    constant c_clock_hz : real := 100_000_000.0;
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

    div1 : entity work.ClockDivider
    generic map
    (
        p_period => 4
    )
    port map
    (
        i_clock => s_clock,
        i_reset => s_reset,
        i_clken => '1',
        o_clken => s_clock_enable_1
    );

    div2 : entity work.ClockDivider
    generic map
    (
        p_period => 2
    )
    port map
    (
        i_clock => s_clock,
        i_reset => s_reset,
        i_clken => s_clock_enable_1,
        o_clken => s_clock_enable_2
    );


end;