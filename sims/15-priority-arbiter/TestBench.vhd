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
    signal s_request : std_logic_vector(3 downto 0);
    signal s_granted : std_logic_vector(3 downto 0);
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

    uut : entity work.PriorityArbiter
    generic map
    (
        p_signal_count => 4
    )
    port map
    ( 
        i_clock => s_clock,
        i_clken => s_clken,
        i_reset => s_reset,
        i_request => s_request,
        o_granted => s_granted
    );

    driver : process(s_clock)
    begin
        if rising_edge(s_clock) then
            if s_reset = '1' then
                s_request <= (others => '0');
            elsif s_clken = '1' then
                s_request <= std_logic_vector(unsigned(s_request) + 1);
            end if;
        end if;
    end process;

end;