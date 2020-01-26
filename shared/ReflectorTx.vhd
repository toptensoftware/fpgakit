--------------------------------------------------------------------------
--
-- ReflectorTx
--
-- Monitor a set of signals and when they change, transmit them via uart
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use work.FunctionLib.all;

entity ReflectorTx is
generic
(
    -- Resolution
    p_clken_hz : integer;                       -- Frequency of the clock
    p_baud : integer := 115200;                 -- Baud Rate
    p_bit_width : integer                       -- Bit width of bits to be reflected
);
port 
( 
    -- Control
    i_clock : in std_logic;                     -- Clock
    i_clken : in std_logic;                     -- Clock Enable
    i_reset : in std_logic;                     -- Reset (synchronous, active high)

    -- Output
    o_uart_tx : out std_logic;                  -- UART TX Signal

    -- Input
    i_signals : in std_logic_vector(p_bit_width-1 downto 0)
);
end ReflectorTx;

architecture Behavioral of ReflectorTx is

    signal s_prev_signals : std_logic_vector(p_bit_width-1 downto 0);

    signal s_tx_data_available : std_logic;
    signal s_tx_busy : std_logic;
    type tx_state is 
    (
        tx_state_idle,
        tx_state_transmitting
    );
    signal s_tx_state : tx_state := tx_state_idle;

begin

    txer : entity work.BitPatternTx
    generic map
    (
        p_clken_hz => p_clken_hz,
        p_baud => p_baud,
        p_bit_width => p_bit_width
    )
    port map
    ( 
        i_clock => i_clock,
        i_clken => i_clken,
        i_reset => i_reset,
        o_uart_tx => o_uart_tx,
        i_data_available => s_tx_data_available,
        i_data => s_prev_signals,
        o_busy => s_tx_busy
    );

    monitor : process(i_clock)
    begin
        if rising_edge(i_clock) then
            if i_reset = '1' then
                s_prev_signals <= (others => '0');
                s_tx_state <= tx_state_idle;
            elsif i_clken = '1' then

                s_tx_data_available <= '0'; 

                case s_tx_state is

                    when tx_state_idle => 
                        -- Currently idle, monitor for changes in any of the signal values and when
                        -- they change, capture the new values and start transmitting them
                        if s_prev_signals /= i_signals then

                            s_prev_signals <= i_signals;
                            s_tx_state <= tx_state_transmitting;
                            s_tx_data_available <= '1';

                        end if;

                    when tx_state_transmitting =>
                        if s_tx_busy = '0' then
                            s_tx_state <= tx_state_idle;
                        end if;

                end case;

            end if;
        end if;
    end process;

end Behavioral;

