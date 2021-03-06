--------------------------------------------------------------------------
--
-- SevenSegmentHexDisplay
-- 
-- Drives a 3-digit 7-segment display
-- 
-- Note: i_clock and i_clken should result in a frequency
--       of about 180Hz (60fps x 3 digits = 180Hz) but isn't 
--       critical - adjust as required.
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use ieee.numeric_std.all;


entity SevenSegmentHexDisplay is
port 
( 
    -- Control
    i_clock : in std_logic;                             -- Clock
    i_clken : in std_logic;                             -- Clock enable (should throttle clock to ~180hz)
    i_reset : in std_logic;                             -- Reset (syncrhonous, actvive high)
       
    -- Input
    i_data : in std_logic_vector(11 downto 0);          -- 12 bit value to be displayed
    
    -- Output
    o_segments : out std_logic_vector(6 downto 0);      -- Segements (active low)
    o_segments_en : out std_logic_vector(2 downto 0)    -- Digit enable (active low)
);
end SevenSegmentHexDisplay;

architecture Behavioral of SevenSegmentHexDisplay is
    signal s_nibble: std_logic_vector(3 downto 0);
    signal s_digit: unsigned(1 downto 0);
begin

    -- Work out which nibble to display
    s_nibble <= 
        i_data(3 downto 0) when s_digit = "00" else
        i_data(7 downto 4) when s_digit = "01" else
        i_data(11 downto 8) when s_digit = "10" else
        "0000";

    -- Work out which digit to enable
    o_segments_en <=
        "110" when s_digit = "00" else
        "101" when s_digit = "01" else
        "011" when s_digit = "10" else
        "111";

	-- Digit decoder
	decoder : entity work.SevenSegmentHexDecoder
	PORT MAP 
	(
		i_data => s_nibble,
		o_segments => o_segments
	);

    -- Clock handler
	process (i_clock)
	begin
        if rising_edge(i_clock) then
            if i_reset = '1' then
                -- Reset
                s_digit <= (others => '0');
            elsif i_clken = '1' then
                -- Increment counter
                s_digit <= s_digit + 1;
            end if;
		end if;
	end process;

end Behavioral;

