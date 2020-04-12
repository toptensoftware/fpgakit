--------------------------------------------------------------------------
--
-- Fifo
--
-- Simple Synchronous FIFO
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use work.FunctionLib.all;

entity Fifo is
generic
(
    p_bit_width : integer;                      -- Bit width of bits to be stored
    p_addr_width : integer                      -- Fifo size
);
port 
( 
    -- Control
    i_clock : in std_logic;                     -- Clock
    i_clken : in std_logic;
    i_reset : in std_logic;                     -- Reset (synchronous, active high)

    -- Input
    i_write : in std_logic;
    i_din : in std_logic_vector(p_bit_width-1 downto 0);

    -- Output
    i_read : in std_logic;
    o_dout : out std_logic_vector(p_bit_width-1 downto 0);

    -- State
    o_full : out std_logic;
    o_empty : out std_logic;
    o_underflow : out std_logic;
    o_overflow : out std_logic;
    o_count : out std_logic_vector(p_addr_width-1 downto 0)
);
end Fifo;

architecture Behavioral of Fifo is

    constant c_length : integer := 2 ** p_addr_width;
    signal s_empty : std_logic := '0';
    signal s_full : std_logic := '0';
    signal s_read_ptr : std_logic_vector(p_addr_width-1 downto 0);
    signal s_write_ptr : std_logic_vector(p_addr_width-1 downto 0);
    signal s_read_ahead_ptr : std_logic_vector(p_addr_width-1 downto 0);
    signal s_next_read_ptr : std_logic_vector(p_addr_width-1 downto 0);
    signal s_next_write_ptr : std_logic_vector(p_addr_width-1 downto 0);
    signal s_overflow : std_logic := '0';
    signal s_underflow : std_logic := '0';

	type mem_type is array(0 to c_length-1) of std_logic_vector(p_bit_width-1 downto 0);
	shared variable ram : mem_type := (others => (others => '0'));

begin

    -- State flags
    s_empty <= '1' when s_read_ptr = s_write_ptr else '0';
    s_full <= '1' when s_next_write_ptr = s_read_ptr else '0';
    o_empty <= s_empty;
    o_full <= s_full;
    o_underflow <= s_underflow;
    o_overflow <= s_overflow;
    o_count <= std_logic_vector(unsigned(s_write_ptr) - unsigned(s_read_ptr));

    -- Other ptrs
    s_next_read_ptr <= std_logic_vector(unsigned(s_read_ptr) + 1);
    s_next_write_ptr <= std_logic_vector(unsigned(s_write_ptr) + 1);
    s_read_ahead_ptr <= s_read_ptr when (i_read = '0' or i_clken = '0') else s_next_read_ptr;

    ram_access : process(i_clock)
    begin
        if rising_edge(i_clock) then

            if i_write = '1' and i_clken = '1' and s_full = '0' then
                ram(to_integer(unsigned(s_write_ptr))) := i_din;
            end if;

            o_dout <= ram(to_integer(unsigned(s_read_ahead_ptr)));

        end if;
    end process;

    writer : process(i_clock)
    begin
        if rising_edge(i_clock) then
            if i_reset = '1' then
                s_overflow <= '0';
                s_write_ptr <= (others => '0');
            else
                if i_write = '1' and i_clken = '1' then
                    if s_full = '1' then
                        s_overflow <= '1';
                    else
                        s_write_ptr <= s_next_write_ptr;
                    end if;
                end if;
            end if;
        end if;
    end process;

    reader : process(i_clock)
    begin
        if rising_edge(i_clock) then
            if i_reset = '1' then
                s_underflow <= '0';
                s_read_ptr <= (others => '0');
            else
                if i_read = '1' and i_clken = '1' then
                    if s_empty = '1' then
                        s_underflow <= '1';
                    else
                        s_read_ptr <= s_next_read_ptr;
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;

