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

    signal s_write : std_logic;
    signal s_din : std_logic_vector(7 downto 0);
    signal s_read : std_logic;
    signal s_dout : std_logic_vector(7 downto 0);
    signal s_full : std_logic;
    signal s_empty : std_logic;
    signal s_underflow : std_logic;
    signal s_overflow : std_logic;

    signal s_counter : integer range 0 to 31;

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

    uut : entity work.Fifo
    generic map
    (
        p_bit_width => 8,
        p_addr_width => 2
    )
    port map
    ( 
        i_clock => s_clock,
        i_clken => s_clken,
        i_reset => s_reset,
        i_write => s_write,
        i_data => s_din,
        i_read => s_read,
        o_data => s_dout,
        o_full => s_full,
        o_empty => s_empty,
        o_underflow => s_underflow,
        o_overflow => s_overflow
    );

    driver : process(s_clock)
    begin
        if rising_edge(s_clock) then

            if s_reset = '1' then
                s_din <= x"A0";
                s_counter <= 0;
            elsif s_clken = '1' then
                if s_counter = 31 then
                    s_counter <= 0;
                else
                    s_counter <= s_counter + 1;
                end if;

                s_write <= '0';
                s_read <= '0';

                case s_counter is
                    when 1 | 5 | 6 | 7 | 8 | 9 =>
                        s_din <= std_logic_vector(unsigned(s_din) + 1);
                        s_write <= '1';

                    when 3 | 10 | 11 | 12 | 13 | 14 =>
                        s_read <= '1';

                    when others =>
                        null;
                end case;

            end if;

        end if;
    end process;


end;
