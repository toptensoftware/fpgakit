--------------------------------------------------------------------------
--
-- PsxIoClient
--
-- Implements wire protocol or a Playstation 1/2 controller
--
-- References:
--     https://store.curiousinventor.com/guides/PS2
--     https://www.raphnet.net/electronique/psx_adaptor/Playstation.txt
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use work.FunctionLib.all;

entity PsxIoClient is
generic
(
    p_clken_hz : integer                            -- In Hz, used to calculate timings
);
port 
( 
    -- Control
    i_clock : in std_logic;                         -- Clock
    i_clken : in std_logic;                         -- Clock Enable
    i_reset : in std_logic;                         -- Reset (synchronous, active high)

    -- Psx Signals
    i_psx_att : in std_logic;
    i_psx_clock : in std_logic;
    i_psx_hoci : in std_logic;
    o_psx_hico : out std_logic;
    o_psx_ack : out std_logic;

    -- Data Inteface
    o_transact_end : out std_logic;                 -- Received transaction
    i_data_tx : in std_logic_vector(7 downto 0);    -- Data byte to transmit in next response
    o_data_rx : out std_logic_vector(7 downto 0);   -- Data byte received in this packet
    o_busy : out std_logic                          -- '1' when transacting    
);
end PsxIoClient;

architecture Behavioral of PsxIoClient is

    constant c_delay_counter_limit : integer := integer(real(p_clken_hz) * 3.0 / 1_000_000.0 + 0.5);
    signal s_delay_counter : integer range 0 to c_delay_counter_limit;

    signal s_bit_counter : integer range 0 to 7;
    signal s_psx_att_sync : std_logic;
    signal s_psx_clock_sync : std_logic;
    signal s_psx_hoci_sync : std_logic;
    signal s_psx_clock_prev : std_logic;
    signal s_psx_clock_edge : std_logic;
    signal s_data_shift_tx : std_logic_vector(7 downto 0);
    signal s_data_shift_rx : std_logic_vector(7 downto 0);

    type states IS
    (
        state_idle,
        state_transact,
        state_pre_ack,
        state_ack
    );
    signal s_state : states := state_idle;

--pragma synthesis_off
signal s_state_integer : integer;
--pragma synthesis_on
begin
--pragma synthesis_off
s_state_integer <= states'pos(s_state);
--pragma synthesis_on

    o_psx_ack <= '0' when s_state = state_ack else '1';
    o_psx_hico <= s_data_shift_tx(0);
    o_data_rx <= s_data_shift_rx;
    o_busy <= '0' when s_state = state_idle else '1';
        
    -- Synchronize signals from master
    sync_ack : entity work.Synchronizer
    port map
    (
        i_clock => i_clock,
        i_reset => i_reset,
        i_signal => i_psx_att,
        o_signal => s_psx_att_sync
    );
    sync_clock : entity work.Synchronizer
    port map
    (
        i_clock => i_clock,
        i_reset => i_reset,
        i_signal => i_psx_clock,
        o_signal => s_psx_clock_sync
    );
    sync_data : entity work.Synchronizer
    port map
    (
        i_clock => i_clock,
        i_reset => i_reset,
        i_signal => i_psx_hoci,
        o_signal => s_psx_hoci_sync
    );

    -- Detect PSX clock edges
    s_psx_clock_edge <= s_psx_clock_sync xor s_psx_clock_prev;
    process (i_clock)
    begin
        if rising_edge(i_clock) then
            if i_reset = '1' then
                s_psx_clock_prev <= '1';
            else
                s_psx_clock_prev <= s_psx_clock_sync;
            end if;
        end if;
    end process;


    -- State machine
    process (i_clock)
    begin
        if rising_edge(i_clock) then
            if i_reset = '1' then
                s_state <= state_idle;
                s_data_shift_rx <= (others => '1');
                s_data_shift_tx <= (others => '1');
                s_bit_counter <= 0;
                o_transact_end <= '0';
            else
                o_transact_end <= '0';
                case s_state is
                    when state_idle =>
                        if s_psx_att_sync = '0' then
                            s_data_shift_rx <= (others => '1');
                            s_data_shift_tx <= (others => '1');
                            s_state <= state_transact;
                            s_bit_counter <= 0;
                        end if;

                    when state_transact =>
                        if s_psx_att_sync = '1' then
                            s_state <= state_idle;
                        else
                            if s_psx_clock_edge = '1' then
                                if s_psx_clock_sync = '0' then 
                                    -- Falling edge, shift out the next bit
                                    if s_bit_counter = 0 then
                                        s_data_shift_tx <= i_data_tx;
                                    else
                                        s_data_shift_tx <= '1' & s_data_shift_tx(7 downto 1);
                                    end if;
                                else
                                    -- Rising edge, shift in the next bit
                                    s_data_shift_rx <= s_psx_hoci_sync & s_data_shift_rx(7 downto 1);

                                    -- End of transaction?
                                    if s_bit_counter = 7 then 
                                        s_state <= state_pre_ack;
                                        s_delay_counter <= 0;
                                        o_transact_end <= '1';
                                        s_bit_counter <= 0;
                                    else
                                        s_bit_counter <= s_bit_counter + 1;
                                    end if;
                                end if;
                            end if;
                        end if;

                    when state_pre_ack =>
                        if s_psx_att_sync = '1' then
                            s_state <= state_idle;
                        else
                            if s_delay_counter = c_delay_counter_limit then
                                s_delay_counter <= 0;
                                s_state <= state_ack;
                            else
                                s_delay_counter <= s_delay_counter + 1;
                            end if;
                        end if;

                    when state_ack =>
                        if s_psx_att_sync = '1' then
                            s_state <= state_idle;
                        else
                            if s_delay_counter = c_delay_counter_limit then
                                s_delay_counter <= 0;
                                s_state <= state_transact;
                            else
                                s_delay_counter <= s_delay_counter + 1;
                            end if;
                        end if;

                end case;
            end if;
        end if;
    end process;

end Behavioral;

