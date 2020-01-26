--------------------------------------------------------------------------
--
-- PsxIoHost
--
-- Handle wire protocol with a Playstation 1/2 controller
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

entity PsxIoHost is
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
    o_psx_clock : out std_logic;
    o_psx_hoci : out std_logic;
    i_psx_hico : in std_logic;
    i_psx_ack : in std_logic;

    -- Data Inteface
    i_transact : in std_logic;                      -- Start a tx/rx transaction
    i_wait_for_ack : in std_logic;                  -- Whether to wait for ack
    i_data_tx : in std_logic_vector(7 downto 0);    -- Data byte to transmit
    o_data_rx : out std_logic_vector(7 downto 0);   -- Data byte received
    o_busy : out std_logic;                         -- '1' when transacting
    o_transact_end : out std_logic;                 -- Pulse when transaction ends
    o_acked : out std_logic                         -- Asserts if controller acked
    
);
end PsxIoHost;

architecture Behavioral of PsxIoHost is
    constant c_psx_clock_hz : integer := 250_000;
    constant c_psx_half_clock_ticks : integer := p_clken_hz / (c_psx_clock_hz * 2);

    signal s_psx_ack_sync : std_logic;
    signal s_psx_hico_sync : std_logic;

    type states IS
    (
        state_idle,
        state_pre,
        state_transact,
        state_wait_ack,
        state_have_ack
    );
    signal s_state : states := state_idle;

    signal s_psx_clock : std_logic;
    signal s_psx_clock_edge : std_logic;
    signal s_half_clock_counter : integer range 0 to c_psx_half_clock_ticks-1;

    signal s_data_shift_tx : std_logic_vector(7 downto 0);
    signal s_data_shift_rx : std_logic_vector(7 downto 0);

    -- Bit counter for each transaction
    -- 0          - pre
    -- 2 - 9      - data
    -- 10 - 35    - wait for ack
    signal s_bit_counter : integer range 0 to 35;

--pragma synthesis_off
signal s_state_integer : integer;
--pragma synthesis_on
begin
--pragma synthesis_off
s_state_integer <= states'pos(s_state);
--pragma synthesis_on

    o_psx_clock <= s_psx_clock when s_bit_counter >= 2 and s_bit_counter <= 9 else '1';
    o_psx_hoci <= s_data_shift_tx(0);
    o_data_rx <= s_data_shift_rx;
    o_busy <= '0' when s_state = state_idle else '1';
        
    -- Synchronize signals from controller
    sync_ack : entity work.Synchronizer
    port map
    (
        i_clock => i_clock,
        i_reset => i_reset,
        i_signal => i_psx_ack,
        o_signal => s_psx_ack_sync
    );
    sync_data : entity work.Synchronizer
    port map
    (
        i_clock => i_clock,
        i_reset => i_reset,
        i_signal => i_psx_hico,
        o_signal => s_psx_hico_sync
    );

    -- Generate the PSX clock and maintain a bit counter
    psx_clock : process(i_clock)
    begin
        if rising_edge(i_clock) then
            if i_reset = '1' or s_state = state_idle then
                s_half_clock_counter <= 0;
                s_psx_clock <= '1';
                s_psx_clock_edge <= '0';
                s_bit_counter <= 0;
            elsif i_clken = '1' then

                s_psx_clock_edge <= '0';
                if s_half_clock_counter = c_psx_half_clock_ticks-1 then
                    s_psx_clock <= not s_psx_clock;
                    s_psx_clock_edge <= '1';
                    s_half_clock_counter <= 0;

                    -- on falling edge of psx clock, bump the bit counter
                    if s_psx_clock = '1' then
                        s_bit_counter <= s_bit_counter + 1;
                    end if;
                else
                    s_half_clock_counter <= s_half_clock_counter + 1;
                end if;
            end if;
        end if;
    end process;

    -- State machine
    process (i_clock)
    begin
        if rising_edge(i_clock) then
            if i_reset = '1' then
                s_state <= state_idle;
                s_data_shift_rx <= (others => '0');
                s_data_shift_tx <= (others => '0');
            else
                o_transact_end <= '0';
                case s_state is
                    when state_idle =>
                        if i_transact = '1' then
                            s_data_shift_rx <= (others => '0');
                            s_data_shift_tx <= i_data_tx;
                            s_state <= state_pre;
                            o_acked <= '0';
                        end if;

                    when state_pre =>
                        if s_psx_clock_edge = '1' and s_psx_clock = '0' and s_bit_counter = 2 then
                            s_state <= state_transact;
                        end if;

                    when state_transact =>
                        if s_psx_clock_edge = '1' then
                            if s_psx_clock = '0' then 
                                -- Falling edge, shift out the next bit
                                s_data_shift_tx <= '1' & s_data_shift_tx(7 downto 1);
                                if s_bit_counter = 10 then 
                                    if i_wait_for_ack = '1' then    
                                        s_state <= state_wait_ack;
                                    else
                                        o_acked <= '1';
                                        s_state <= state_idle;
                                        o_transact_end <= '1';
                                    end if;
                                end if;
                            else
                                -- Rising edge, shift in the next bit
                                s_data_shift_rx <= s_psx_hico_sync & s_data_shift_rx(7 downto 1);
                            end if;
                        end if;

                    when state_wait_ack => 
                        if s_psx_clock_edge = '1' then
                            -- Ack signal received?
                            if s_psx_ack_sync = '0' then 
                                o_acked <= '1';
                                s_state <= state_have_ack;
                            end if;

                            -- Allow 25 clock ticks to ack
                            -- (need to allow 100us, and at 250Khz each clock tick is 4us)
                            if s_bit_counter = 35 then
                                s_state <= state_idle;
                                o_transact_end <= '1';
                            end if;
                        end if;

                    when state_have_ack => 
                        if s_psx_clock_edge = '1' then
                            -- Wait for ack to de-assert...
                            if s_psx_ack_sync = '1' then
                                s_state <= state_idle;
                                o_transact_end <= '1';
                            end if;

                            -- ...or time out
                            if s_bit_counter = 35 then
                                s_state <= state_idle;                            
                                o_transact_end <= '1';
                            end if;
                        end if;
                    
                end case;
            end if;
        end if;
    end process;

end Behavioral;

