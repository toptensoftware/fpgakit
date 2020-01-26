--------------------------------------------------------------------------
--
-- PsxControllerHost
--
-- Handle byte protocol with a Playstation 1/2 controller
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

entity PsxControllerHost is
generic
(
    p_clken_hz : integer;                           -- In Hz, used to calculate timings
    p_poll_hz : integer                             -- How often to poll the controller
);
port 
( 
    -- Control
    i_clock : in std_logic;                         -- Clock
    i_clken : in std_logic;                         -- Clock Enable
    i_reset : in std_logic;                         -- Reset (synchronous, active high)

    -- Psx Signals
    o_psx_att : out std_logic;
    o_psx_clock : out std_logic;
    o_psx_hoci : out std_logic;
    i_psx_hico : in std_logic;
    i_psx_ack : in std_logic;

    -- Data Inteface
    o_connected : out std_logic;                    -- asserts if controller is responding
    o_buttons : out std_logic_vector(15 downto 0)  -- current state of all buttons
);
end PsxControllerHost;

architecture Behavioral of PsxControllerHost is

    constant c_poll_ticks : integer := p_clken_hz / p_poll_hz;
    signal s_poll : std_logic;
    signal s_buttons : std_logic_vector(15 downto 0);

    signal s_transact : std_logic;
    signal s_wait_for_ack : std_logic;
    signal s_data_tx : std_logic_vector(7 downto 0);
    signal s_data_rx : std_logic_vector(7 downto 0);
    signal s_transact_end : std_logic;
    signal s_acked : std_logic;

    type states is
    (
        state_idle,
        state_wait,
        state_byte0,
        state_byte1,
        state_byte2,
        state_byte3,
        state_byte4,
        state_eotx
    );
    signal s_state : states := state_idle;
    signal s_state_next : states := state_idle;
begin

    o_buttons <= s_buttons;

    poll_timer : entity work.ClockDivider
    generic map
    (
        p_period => c_poll_ticks
    )
    port map
    ( 
        i_clock => i_clock,
        i_clken => i_clken,
        i_reset => i_reset,
        o_clken => s_poll
    );

    psxio : entity work.PsxIoHost
    generic map 
    (
        p_clken_hz => p_clken_hz
    )
    port map
    ( 
        i_clock => i_clock,
        i_clken => i_clken,
        i_reset => i_reset,
        o_psx_clock => o_psx_clock,
        o_psx_hoci => o_psx_hoci,
        i_psx_hico => i_psx_hico,
        i_psx_ack => i_psx_ack,
        i_transact => s_transact,
        i_wait_for_ack => s_wait_for_ack,
        i_data_tx => s_data_tx,
        o_data_rx => s_data_rx,
        o_busy => open,
        o_transact_end => s_transact_end,
        o_acked => s_acked
    );
        
    o_psx_att <= '1' when s_state = state_idle else '0';

    poll_proc : process(i_clock)
    begin
        if rising_edge(i_clock) then
            if i_reset = '1' then

                s_transact <= '0';
                s_wait_for_ack <= '1';
                s_data_tx <= (others => '0');
                s_state <= state_idle;
                s_state_next <= state_idle;
                s_buttons <= (others => '0');
                o_connected <= '0';

            elsif i_clken = '1' then

                s_transact <= '0';

                case s_state is

                    when state_idle =>
                        if s_poll = '1' then
                            s_state <= state_byte0;
                        end if;

                    when state_wait => 
                        if s_transact_end = '1' then
                            if s_acked = '1' then
                                s_state <= s_state_next;
                            else
                                s_state <= state_idle;
                                o_connected <= '0';
                                s_buttons <= (others => '0');
                            end if;
                        end if;

                    when state_byte0 => 
                        s_transact <= '1';
                        s_wait_for_ack <= '1';
                        s_data_tx <= x"01";
                        s_state_next <= state_byte1;
                        s_state <= state_wait;

                    when state_byte1 =>
                        s_transact <= '1';
                        s_data_tx <= x"42";
                        s_state_next <= state_byte2;
                        s_state <= state_wait;

                    when state_byte2 =>
                        if s_data_rx /= x"41" then
                            s_state <= state_idle;
                            s_buttons <= (others => '0');
                            o_connected <= '0';
                        else
                            s_transact <= '1';
                            s_data_tx <= x"00";
                            s_state_next <= state_byte3;
                            s_state <= state_wait;
                        end if;

                    when state_byte3 =>
                        s_transact <= '1';
                        s_data_tx <= x"00";
                        s_state_next <= state_byte4;
                        s_state <= state_wait;

                    when state_byte4 =>
                        s_buttons(7 downto 0) <= not s_data_rx;
                        s_transact <= '1';
                        s_data_tx <= x"00";
                        s_state_next <= state_eotx;
                        s_state <= state_wait;
                        s_wait_for_ack <= '0';

                    when state_eotx =>
                        s_buttons(15 downto 8) <= not s_data_rx;
                        s_state <= state_idle;
                        o_connected <= '1';
                        
                end case;
            end if;
        end if;
    end process;

end Behavioral;

