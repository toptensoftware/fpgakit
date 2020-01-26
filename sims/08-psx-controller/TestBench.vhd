library ieee;
use IEEE.numeric_std.all;
use ieee.std_logic_1164.all;

entity TestBench is
end TestBench;

architecture behavior of TestBench is
    constant c_clock_hz : real := 10_000_000.0;
    signal s_clock : std_logic := '0';
    signal s_reset : std_logic;
    signal s_host_transact : std_logic;
    signal s_host_transact_end : std_logic;
    signal s_host_data_tx : std_logic_vector(7 downto 0);
    signal s_host_data_rx : std_logic_vector(7 downto 0);
    signal s_client_att : std_logic;
    signal s_client_transact_end : std_logic;
    signal s_client_data_tx : std_logic_vector(7 downto 0);
    signal s_client_data_rx : std_logic_vector(7 downto 0);
    signal s_psx_clock : std_logic;
    signal s_psx_hoci : std_logic;
    signal s_psx_hico : std_logic;
    signal s_psx_ack : std_logic;
    signal s_psx_busy : std_logic;

    signal s_client_buttons : std_logic_vector(15 downto 0) := x"0001";
begin

    reset_proc: process
    begin
        s_reset <= '1';
        wait until falling_edge(s_clock);
        wait until rising_edge(s_clock);
        wait until falling_edge(s_clock);
        s_reset <= '0';
        wait;
    end process;

    stim_proc: process
    begin
        s_clock <= not s_clock;
        wait for 1 sec / (c_clock_hz * 2.0);
    end process;


    client : entity work.PsxIoClient
    generic map
    (
        p_clken_hz => integer(c_clock_hz)
    )
    port map 
    ( 
        i_clock => s_clock,
        i_clken => '1',
        i_reset => s_reset,
        i_psx_att => s_client_att,
        i_psx_clock => s_psx_clock,
        i_psx_hoci => s_psx_hoci,
        o_psx_hico => s_psx_hico,
        o_psx_ack => s_psx_ack,
        o_transact_end => s_client_transact_end,
        i_data_tx => s_client_data_tx,
        o_data_rx => s_client_data_rx,
        o_busy => open
    );


    controller_host : entity work.PsxControllerHost
    generic map
    (
        p_clken_hz => integer(c_clock_hz),
        p_poll_hz => 2000
    )
    port map 
    ( 
        i_clock => s_clock,
        i_clken => '1',
        i_reset => s_reset,
        o_psx_att => s_client_att,
        o_psx_clock => s_psx_clock,
        o_psx_hoci => s_psx_hoci,
        i_psx_hico => s_psx_hico,
        i_psx_ack => s_psx_ack,
        o_connected => open,
        o_buttons => open
    );

    client_driver : process
    begin
        s_client_data_tx <= x"FF";

        wait until s_client_transact_end = '1';
        s_client_data_Tx <= x"41";

        wait until s_client_transact_end = '1';
        s_client_data_tx <= x"5a";

        wait until s_client_transact_end = '1';
        s_client_data_tx <= not s_client_buttons(7 downto 0);

        wait until s_client_transact_end = '1';
        s_client_data_tx <= not s_client_buttons(15 downto 8);

        wait until s_client_transact_end = '1';

    end process;

    buttons_driver : process
    begin
        wait for 300 us;
        s_client_buttons <= x"0c04";
        wait;
    end process;
end;