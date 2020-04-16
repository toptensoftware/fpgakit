--------------------------------------------------------------------------
--
-- SysConSerialPort
--
-- Implements a buffered serial port
-- 
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SysConSerialPort is
port
(
	-- Clocking
	i_reset : in std_logic;
    i_clock : in std_logic;

	-- CPU connection
	i_cpu_port_number : in std_logic_vector(1 downto 0);
	i_cpu_port_wr_rising_pulse : in std_logic;
	i_cpu_port_rd_falling_edge : in std_logic;
	o_cpu_din : out std_logic_vector(7 downto 0);
	i_cpu_dout : in std_logic_vector(7 downto 0);

	-- IRQs
	o_irq_rx : out std_logic;		-- anytime anything in receive queue
	o_irq_tx : out std_logic;		-- when transmit buffer becomes empty

	-- UART
	o_uart_tx : out std_logic;
	i_uart_rx : in std_logic

);
end SysConSerialPort;

architecture Behavioral of SysConSerialPort is
	signal s_uart_tx_write : std_logic;
	signal s_uart_tx_din : std_logic_vector(7 downto 0);
	signal s_uart_tx_count : std_logic_vector(7 downto 0);
	signal s_uart_tx_full : std_logic;
	signal s_uart_rx_read : std_logic;
	signal s_uart_rx_dout : std_logic_vector(7 downto 0);
	signal s_uart_rx_count : std_logic_vector(7 downto 0);
	signal s_uart_rx_empty : std_logic;
	signal s_not_uart_rx_empty : std_logic;
	signal s_not_uart_tx_full : std_logic;
begin

	o_cpu_din <=
		s_uart_tx_count when i_cpu_port_number = "00" else
		s_uart_rx_count when i_cpu_port_number = "01" else
		s_uart_rx_dout;

	s_not_uart_rx_empty  <= not s_uart_rx_empty;
	s_not_uart_tx_full <= not s_uart_tx_full;

	e_delayed_rx_irq : entity work.DelayedSignal
	generic map
	(
		p_delay_period => 80_000_000 / 1_000 * 11			-- 11 milliseconds
	)
	port map
	(
		i_clock => i_clock,
		i_clken => '1',
		i_reset => i_reset,
		i_signal => s_not_uart_rx_empty,
		o_signal => o_irq_rx
	);

	e_delayed_tx_irq : entity work.DelayedSignal
	generic map
	(
		p_delay_period => 80_000_000 / 1_000 * 11			-- 11 milliseconds
	)
	port map
	(
		i_clock => i_clock,
		i_clken => '1',
		i_reset => i_reset,
		i_signal => s_not_uart_tx_full,
		o_signal => o_irq_tx
	);


	port_handler : process(i_clock)
	begin
		if rising_edge(i_clock) then
			if i_reset = '1' then
				s_uart_tx_write <= '0';
				s_uart_rx_read <= '0';
			else

				s_uart_tx_write <= '0';
				s_uart_rx_read <= '0';

				if i_cpu_port_wr_rising_pulse = '1' and i_cpu_port_number = "00" then
					s_uart_tx_din <= i_cpu_dout;
					s_uart_tx_write <= '1';
				end if;

				if i_cpu_port_rd_falling_edge = '1' and i_cpu_port_number = "10" then
					s_uart_rx_read <= '1';
				end if;

			end if;
		end if;
	end process;

	-- Uart transmitter
	uart_tx : entity work.UartTxBuffered
	generic map
	(
		p_clken_hz => 80_000_000,
		p_baud => 115200,
		p_addr_width => 8
	)
	port map
	( 
		i_clock => i_clock,
		i_clken => '1',
		i_reset => i_reset,
		i_write => s_uart_tx_write,
		i_din => s_uart_tx_din,
		o_uart_tx => o_uart_tx,
		o_busy => open,
		o_full => s_uart_tx_full,
		o_empty => open,
		o_underflow => open,
		o_overflow => open,
		o_count => s_uart_tx_count
	);

	uart_rx : entity work.UartRxBuffered
	generic map
	(
		p_clock_hz => 80_000_000,
		p_baud => 115200,
		p_sync => true,
		p_debounce => true,
		p_addr_width => 8
	)
	port map
	( 
		i_clock => i_clock,
		i_reset => i_reset,
		i_uart_rx => i_uart_rx,
		i_read => s_uart_rx_read,
		o_dout => s_uart_rx_dout,
		o_busy => open,
		o_error => open,
		o_full => open,
		o_empty => s_uart_rx_empty,
		o_underflow => open,
		o_overflow => open,
		o_count => s_uart_rx_count
	);

end Behavioral;

--xilt:nowarn:~WARNING:Par:288 - The signal (.+)/uart_.x/fifo
--xilt:nowarn:~WARNING:PhysDesignRules:367 - The signal <(.+)/uart_.x/fifo