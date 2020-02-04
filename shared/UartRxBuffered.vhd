--------------------------------------------------------------------------
--
-- UartRxBufferedBuffered
--
-- Buffered UART Receive Module
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use work.FunctionLib.all;

entity UartRxBuffered is
generic
(
    -- Resolution
    p_clock_hz : integer;                       -- Frequency of the clock
    p_baud : integer := 115200;                 -- Baud Rate
    p_sync: boolean := true;                    -- Sync the i_uart_rx signal to this clock domain
    p_debounce: boolean := true;                -- Debounce the incoming signal
    p_addr_width : integer                      -- Size of the buffer
);
port 
( 
    -- Control
    i_clock : in std_logic;                     -- Clock
    i_reset : in std_logic;                     -- Reset (synchronous, active high)

    -- Input
    i_uart_rx : in std_logic;                   -- UART TX Signal

    -- Output
    i_read : in std_logic;
    o_dout : out std_logic_vector(7 downto 0);

    -- Status
    o_busy : out std_logic;                  -- '1' when receiving
    o_error : out std_logic;                  -- stop bit error
    o_full : out std_logic;
    o_empty : out std_logic;
    o_underflow : out std_logic;
    o_overflow : out std_logic;
    o_count : out std_logic_vector(p_addr_width-1 downto 0)
);
end UartRxBuffered;

architecture Behavioral of UartRxBuffered is
    signal s_uart_data : std_logic_vector(7 downto 0);
    signal s_uart_data_available : std_logic;
    signal s_fifo_write : std_logic;
begin

    uart_rx : entity work.UartRx
    generic map
    (
        p_clock_hz => p_clock_hz,
        p_baud => p_baud,
        p_sync => p_sync,
        p_debounce => p_debounce
    )
    port map
    ( 
        i_clock => i_clock,
        i_reset => i_reset,
        i_uart_rx => i_uart_rx,
        o_data => s_uart_data,
        o_data_available => s_uart_data_available,
        o_busy => o_busy,
        o_error => o_error
    );

    fifo : entity work.Fifo
    generic map
    (
        p_bit_width => 8,
        p_addr_width => p_addr_width
    )
    port map
    ( 
        i_clock => i_clock,
        i_clken => '1',
        i_reset => i_reset,
        i_write => s_uart_data_available,
        i_din => s_uart_data,
        i_read => i_read,
        o_dout => o_dout,
        o_full => o_full,
        o_empty => o_empty,
        o_underflow => o_underflow,
        o_overflow => o_overflow,
        o_count => o_count
    );

end Behavioral;

