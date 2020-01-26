--------------------------------------------------------------------------
--
-- EdgeDetector
--
-- Detects signal edges and converts to pulse
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use work.FunctionLib.all;

entity EdgeDetector is
generic
(
    p_default_state : std_logic := '0';     -- Starting state after reset
    p_falling_edge : boolean := false;      -- Generate pulse on rising edge
    p_rising_edge : boolean := true;       -- Generate pulse on falling edge
    p_pulse : std_logic := '1'              -- Value of pulse to generate (ie: active high/low)
);
port 
( 
    -- Control
    i_clock : in std_logic;                 -- Clock
    i_clken : in std_logic;                 -- Clock enable
    i_reset : in std_logic;                 -- Reset (synchronous, active high)

    -- Inputs
    i_signal : in std_logic;                -- The input signal
    
    -- Output
    o_pulse : out std_logic                 -- Pulse for one clock cycle when edge detected
);
end EdgeDetector;

architecture Behavioral of EdgeDetector is
    signal s_previous : std_logic;
begin

    g1 : if p_falling_edge and p_rising_edge generate
        o_pulse <= ((i_signal xor s_previous) and i_clken) xor not p_pulse;
    end generate;

    g2: if p_falling_edge and not p_rising_edge generate
        o_pulse <= (s_previous and not i_signal and i_clken) xor not p_pulse;
    end generate;

    g3: if not p_falling_edge and p_rising_edge generate
        o_pulse <= (not s_previous and i_signal and i_clken) xor not p_pulse;
    end generate;

    g4: if not p_falling_edge and not p_rising_edge generate
        o_pulse <= not p_pulse;
    end generate;

    process (i_clock)
    begin
        if rising_edge(i_clock) then
            if i_reset = '1' then
                s_previous <= p_default_state;
            elsif i_clken = '1' then
                s_previous <= i_signal;
            end if;
        end if;        
    end process;
  
end Behavioral;

