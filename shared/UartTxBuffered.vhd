--------------------------------------------------------------------------
--
-- UartTxBuffered
--
-- Simple buffered UART TX module - no parity bit, 1 start and 1 stop bit
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.FunctionLib.all;

entity UartTxBuffered is
generic
(
    p_clken_hz : integer;                       -- Frequency of the clock
    p_baud : integer := 115200;                 -- Baud Rate
    p_addr_width : integer                      -- Size of the buffer
);
port 
( 
    -- Control
    i_clock : in std_logic;                     -- Clock
    i_clken : in std_logic;                     -- Clock Enable
    i_reset : in std_logic;                     -- Reset (synchronous, active high)

    -- Input
    i_write : in std_logic;                     -- Write enable
    i_din : in std_logic_vector(7 downto 0);    -- Data to be transmitted

    -- Output
    o_uart_tx : out std_logic;                  -- UART TX Signal

    -- Status
    o_busy : out std_logic;                     -- '1' when transmitting
    o_full : out std_logic;
    o_empty : out std_logic;
    o_underflow : out std_logic;
    o_overflow : out std_logic;
    o_count : out std_logic_vector(p_addr_width-1 downto 0)
);
end UartTxBuffered;

architecture Behavioral of UartTxBuffered is    
    signal s_uart_write : std_logic;
    signal s_uart_busy : std_logic;
    signal s_fifo_read : std_logic;
    signal s_fifo_dout : std_logic_vector(7 downto 0);
    signal s_fifo_empty : std_logic;
    signal s_fifo_not_empty : std_logic;
begin

    o_empty <= s_fifo_empty;
    o_busy <= s_uart_busy;

    uart : entity work.UartTx
    generic map
    (
        p_clken_hz => p_clken_hz,
        p_baud => p_baud
    )
    port map
    ( 
        i_clock => i_clock,
        i_clken => i_clken,
        i_reset => i_reset,
        i_data => s_fifo_dout,
        i_data_available => s_uart_write,
        o_uart_tx => o_uart_tx,
        o_busy => s_uart_busy
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
        i_write => i_write,
        i_din => i_din,
        i_read => s_fifo_read,
        o_dout => s_fifo_dout,
        o_full => o_full,
        o_empty => s_fifo_empty,
        o_underflow => o_underflow,
        o_overflow => o_overflow,
        o_count => o_count
    );

    exec : process(i_clock)
    begin
        if rising_edge(i_clock) then
            if i_reset = '1' then
                s_uart_write <= '0';
                s_fifo_read <= '0';
            else
                s_uart_write <= '0';
                s_fifo_read <= '0';
                if s_uart_busy = '0' and s_fifo_empty = '0' then
                    s_uart_write <= '1';
                    s_fifo_read <= '1';
                end if;
            end if;
        end if;
    end process;

end Behavioral;

