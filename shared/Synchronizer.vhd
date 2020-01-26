--------------------------------------------------------------------------
--
-- Synchronizer
--
-- Synchronizes a signal from a different clock domain
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use work.FunctionLib.all;

entity Synchronizer is
port 
( 
    -- Control
    i_clock : in std_logic;         -- Clock
    i_reset : in std_logic;         -- Reset (synchronous, active high)

    -- Inputs
    i_signal : in std_logic;
    
    -- Output
    o_signal : out std_logic
);
end Synchronizer;

architecture Behavioral of Synchronizer is
    signal s_sync_1 : std_logic;
    signal s_sync_2 : std_logic;
begin

    o_signal <= s_sync_2;

    sync : process(i_clock)
    begin
        if rising_edge(i_clock) then
            if i_reset = '1' then
                s_sync_1 <= '0';
                s_sync_2 <= '0';
            else
                s_sync_1 <= i_signal;
                s_sync_2 <= s_sync_1;
            end if;
        end if;
    end process; 


end Behavioral;

