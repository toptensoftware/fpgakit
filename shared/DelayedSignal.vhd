--------------------------------------------------------------------------
--
-- DelayedSignal
--
-- Delays a rising edge signal by a specified number of clock ticks
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use work.FunctionLib.all;

entity DelayedSignal is
generic
(
    p_delay_period : integer               -- Delay in clock ticks
);
port 
( 
    -- Control
    i_clock : in std_logic;                 -- Clock
    i_clken : in std_logic;                 -- Clock Enable
    i_reset : in std_logic;                 -- Reset (synchronous, active high)

    -- Inputs
    i_signal : in std_logic;                -- The input signal
    
    -- Output
    o_signal : out std_logic                -- The output debounced signal
);
end DelayedSignal;

architecture Behavioral of DelayedSignal is
    signal s_counter : integer range 0 to p_delay_period - 1;
    signal s_previous : std_logic;
begin

    -- Output the filtered signal register
    o_signal <= '1' when s_counter = 0 and i_signal = '1' else '0';

    process (i_clock)
    begin
        if rising_edge(i_clock) then
            if i_reset = '1' then
                s_counter <= p_delay_period -1;
            elsif i_clken = '1' then

                if i_signal = '1' then
                    if s_counter /= 0 then
                        s_counter <= s_counter - 1;
                    end if;
                else
                    s_counter <= p_delay_period -1;
                end if;

            end if;
        end if;        
    end process;
  
end Behavioral;

