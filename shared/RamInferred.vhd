--------------------------------------------------------------------------
--
-- RamInferred
--
-- Infers a single port RAM of specified address and data width
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity RamInferred is
	generic
	(
		p_addr_width : integer;
		p_data_width : integer := 8
	);
	port
	(
		-- Port A
		i_clock : in std_logic;
		i_clken : in std_logic;
		i_addr : in std_logic_vector(p_addr_width-1 downto 0);
		i_data : in std_logic_vector(p_data_width-1 downto 0);
		o_data : out std_logic_vector(p_data_width-1 downto 0);
		i_write : in std_logic;
		i_write_mask : in std_logic_vector((p_data_width / 8)-1 downto 0)
	);
end RamInferred;
 
architecture behavior of RamInferred is 
	constant c_mem_depth : integer := 2**p_addr_width;
	type mem_type is array(0 to c_mem_depth-1) of std_logic_vector(p_data_width-1 downto 0);
	shared variable ram : mem_type;
	signal s_wr_data : std_logic_vector(p_data_width - 1 downto 0);
begin

	gen_wr_data : for ii in 0 to (p_data_width / 8) - 1 generate
		s_wr_data(ii * 8 + 7 downto ii * 8) <= 
			i_data(ii * 8 + 7 downto ii * 8)
			when i_write_mask(ii) = '0' else
			ram(to_integer(unsigned(i_addr)))(ii * 8 + 7 downto ii * 8);
	end generate gen_wr_data;

	process (i_clock)
	begin
		if rising_edge(i_clock) then
			if i_clken = '1' then

				if i_write = '1' then
					ram(to_integer(unsigned(i_addr))) := s_wr_data;
				end if;

				o_data <= ram(to_integer(unsigned(i_addr)));

			end if;
		end if;
	end process;

end;
