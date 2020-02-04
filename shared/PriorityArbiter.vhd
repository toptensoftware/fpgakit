--------------------------------------------------------------------------
--
-- Priority Arbiter
--
-- Simple N-channel priority arbiter
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PriorityArbiter is
generic 
( 
	p_signal_count : integer
);
port 
(
	i_clock : in std_logic;
	i_clken : in std_logic;
	i_reset : in std_logic;
	i_request : in std_logic_vector(p_signal_count-1 downto 0);
	o_granted : out std_logic_vector(p_signal_count-1 downto 0)
);
end PriorityArbiter;

architecture Behavioral of PriorityArbiter IS
	signal s_granted : std_logic_vector(p_signal_count-1 downto 0);
begin

	o_granted <= s_granted;

	process (i_clock)
	begin

		if rising_edge(i_clock) then
			if i_reset='1' then

				s_granted <= (others => '0');

			elsif i_clken='1' then

				if (s_granted and i_request) = (s_granted'range => '0') then
				
					s_granted <= i_request and std_logic_vector(unsigned(not(i_request)) + 1);

				end if;

			end if;
		end if;

	end process;
end Behavioral;


