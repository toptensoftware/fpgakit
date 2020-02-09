--------------------------------------------------------------------------
--
-- FakeSDCardController
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use work.FunctionLib.all;

entity FakeSDCardController is
port 
( 
    -- Clocking
	i_reset : in std_logic;
	i_clock : in std_logic;

    -- SD Port
	o_status : out std_logic_vector(7 downto 0);
	i_op_write : in std_logic;
	i_op_cmd : in std_logic_vector(1 downto 0);
	i_op_block_number : in std_logic_vector(31 downto 0);
	o_data_start : out std_logic;
	o_data_cycle : out std_logic;
	i_din : in std_logic_vector(7 downto 0);
	o_dout : out std_logic_vector(7 downto 0)
);
end FakeSDCardController;

architecture Behavioral of FakeSDCardController is
    signal s_delay : integer range 0 to 31;
    signal s_bufpos : integer range 0 to 511;
    type state is
    (
        state_init,
        state_idle,
        state_will_read,
        state_reading,
        state_did_read,
        state_will_write,
        state_writing,
        state_did_write
    );
    signal s_state : state := state_init;
begin

    o_status(0) <= '1' when s_state /= state_idle else '0';      -- Busy
    o_status(1) <= '1' when s_state = state_reading or s_state = state_will_read or s_state = state_did_read else '0';
    o_status(2) <= '1' when s_state = state_writing or s_state = state_will_write or s_state = state_did_write else '0';
    o_status(3) <= '0';                                          -- Error
    o_status(4) <= '1' when s_state /= state_init else '0';      -- Initialize
    o_status(5) <= '0';                                          -- Unused
    o_status(6) <= '0';                                          -- Unused
    o_status(7) <= '1' when s_state /= state_init else '0';      -- SDHC

    o_dout <= std_logic_vector(to_unsigned(s_bufpos, o_dout'length));

    exec : process(i_clock)
    begin
        if rising_edge(i_clock) then
            if i_reset = '1' then
                s_delay <= 0;
                s_state <= state_init;
                o_data_start <= '0';
                o_data_cycle <= '0';
            else
                o_data_start <= '0';
                o_data_cycle <= '0';

                case s_state is
                    when state_init =>
                        if s_delay = 31 then
                            s_state <= state_idle;
                            s_delay <= 0;
                        else
                            s_delay <= s_delay + 1;
                        end if;

                    when state_idle =>
                        if i_op_write = '1' then
                            if i_op_cmd = "01" then
                                s_state <= state_will_read;
                            elsif i_op_cmd = "00" then
                                s_state <= state_will_write;
                            end if;
                        end if;

                    when state_will_read =>
                        if s_delay = 15 then
                            s_state <= state_reading;
                            s_delay <= 0;
                            s_bufpos <= 0;
                            o_data_start <= '1';
                        else
                            s_delay <= s_delay + 1;
                        end if;

                    when state_reading =>
                        if s_delay = 15 then
                            s_delay <= 0;
                            o_data_cycle <= '1';
                            if s_bufpos = 3 then
                                s_bufpos <= 0;
                                s_state <= state_did_read;
                            else
                                s_bufpos <= s_bufpos + 1;
                            end if;
                        else
                            s_delay <= s_delay + 1;
                        end if;

                    when state_did_read =>
                        if s_delay = 15 then
                            s_state <= state_idle;
                            s_delay <= 0;
                            s_bufpos <= 0;
                        else
                            s_delay <= s_delay + 1;
                        end if;

                    when state_will_write =>
                        if s_delay = 15 then
                            s_state <= state_writing;
                            s_delay <= 0;
                            s_bufpos <= 0;
                            o_data_start <= '1';
                        else
                            s_delay <= s_delay + 1;
                        end if;

                    when state_writing =>
                        if s_delay = 15 then
                            s_delay <= 0;
                            o_data_cycle <= '1';
                            if s_bufpos = 3 then
                                s_bufpos <= 0;
                                s_state <= state_did_write;
                            else
                                s_bufpos <= s_bufpos + 1;
                            end if;
                        else
                            s_delay <= s_delay + 1;
                        end if;

                    when state_did_write =>
                        if s_delay = 15 then
                            s_state <= state_idle;
                            s_delay <= 0;
                            s_bufpos <= 0;
                        else
                            s_delay <= s_delay + 1;
                        end if;

                end case;
            end if;
        end if;
    end process;

end Behavioral;

