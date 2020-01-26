--------------------------------------------------------------------------
--
-- LogicCapture
--
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use work.FunctionLib.all;

entity LogicCapture is
generic
(
    p_clock_hz : integer;                       -- Frequency of the clock
    p_baud : integer := 115200;                 -- Baud Rate
    p_bit_width : integer;                      -- Bit width of bits to be capture
    p_addr_width : integer
);
port 
( 
    -- Control
    i_clock : in std_logic;             -- Clock
    i_clken : in std_logic;             -- Clock Enable for clock being divided
    i_reset : in std_logic;             -- Reset (synchronous, active high)

    -- Signals
    i_trigger : in std_logic;   
    i_signals : in std_logic_vector(p_bit_width-1 downto 0);

    -- Transmit
    o_uart_tx : out std_logic
);
end LogicCapture;

architecture Behavioral of LogicCapture is
    signal s_triggered : std_logic;
    signal s_full : std_logic;

    signal s_addr_a : std_logic_vector(p_addr_width-1 downto 0);
    signal s_addr_a_next : std_logic_vector(p_addr_width-1 downto 0);
    signal s_write_a : std_logic;

    signal s_addr_b : std_logic_vector(p_addr_width-1 downto 0);
    signal s_dout_b : std_logic_vector(p_bit_width-1 downto 0);

    signal s_tx_data_available : std_logic;
    signal s_tx_busy : std_logic;

    type tx_state is 
    (
        tx_state_idle,
        tx_state_transmitting
    );
    signal s_tx_state : tx_state := tx_state_idle;
begin

    s_addr_a_next <= std_logic_vector(unsigned(s_addr_a) + 1);

    ram : entity work.RamDualPortInferred
	generic map
	(
		p_addr_width => p_addr_width,
		p_data_width => p_bit_width
	)
	port map
	(
        -- Port A capture record
		i_clock_a => i_clock,
		i_clken_a => i_clken,
		i_addr_a => s_addr_a,
		i_data_a => i_signals,
		o_data_a => open,
		i_write_a => s_write_a,

        -- Port B serial sender
		i_clock_b => i_clock,
		i_clken_b => '1',
		i_addr_b => s_addr_b,
		i_data_b => (others => '0'),
		o_data_b => s_dout_b,
		i_write_b => '0'
	);

    s_write_a <= (s_triggered or i_trigger) and not s_full;

	writer : process (i_clock)
	begin
		if rising_edge(i_clock) then
            if i_reset='1' then

                s_addr_a <= (others => '0');
                s_triggered <= '0';
                s_full <= '0';

            elsif i_clken = '1' then

                -- If triggered and not full then write to buffer
                if s_write_a = '1' then
                    s_triggered <= '1';

                    -- If caught up to read pointer then full, stop.
                    if s_addr_a_next = s_addr_b then
                        s_full <= '1';
                    else
                        s_addr_a <= s_addr_a_next;
                    end if;
                end if;

            end if;
        end if;
	end process;

	reader : process (i_clock)
	begin
		if rising_edge(i_clock) then
            if i_reset='1' then

                s_tx_state <= tx_state_idle;
                s_tx_data_available <= '0';
                s_addr_b <= (others => '0');

            else
                s_tx_data_available <= '0';

                case s_tx_state is

                    when tx_state_idle => 

                        if s_addr_b /= s_addr_a then

                            s_addr_b <= std_logic_vector(unsigned(s_addr_b) + 1);
                            s_tx_data_available <= '1';
                            s_tx_state <= tx_state_transmitting;

                        end if;

                    when tx_state_transmitting =>
                        if s_tx_busy = '0' then
                            s_tx_state <= tx_state_idle;
                        end if;

                end case;

            end if;
        end if;
	end process;

    txer : entity work.BitPatternTx
    generic map
    (
        p_clken_hz => p_clock_hz,
        p_baud => p_baud,
        p_bit_width => p_bit_width
    )
    port map
    ( 
        i_clock => i_clock,
        i_clken => '1',
        i_reset => i_reset,
        o_uart_tx => o_uart_tx,
        i_data_available => s_tx_data_available,
        i_data => s_dout_b,
        o_busy => s_tx_busy
    );

end Behavioral;

