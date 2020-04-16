--------------------------------------------------------------------------
--
-- SysConInterruptController
--
-- Interrupt Controller - handles generating NMI and switching
-- to/from hijack mode
-- 
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SysConInterruptController is
generic
(
	p_irq_count : integer
);
port
(
	-- Clocking
	i_reset : in std_logic;
    i_clock : in std_logic;
	i_clken : in std_logic;

	-- CPU connection
	i_cpu_port_wr : in std_logic;
	i_cpu_port_rd : in std_logic;
	i_cpu_addr : in std_logic_vector(15 downto 0);
	i_cpu_din : in std_logic_vector(7 downto 0);
	i_cpu_dout : in std_logic_vector(7 downto 0);
	i_cpu_m1_n : in std_logic;
	i_cpu_wait_n : in std_logic;

	-- IRQs
	i_irqs : std_logic_vector(p_irq_count - 1 downto 0);

	-- Control signals
	o_hijacked : out std_logic;
	o_nmi_n : out std_logic;
	o_is_ic_port : out std_logic;
	o_cpu_din : out std_logic_vector(7 downto 0)
);
end SysConInterruptController;

architecture Behavioral of SysConInterruptController is
	signal s_hijacked : std_logic := '1';
	signal s_nmi_n : std_logic;
	signal s_exit_hijack_mode : std_logic := '0';
	signal s_is_ic_port : std_logic;
	signal s_prev_irqs : std_logic_vector(p_irq_count-1 downto 0);				-- for edge detection
	signal s_raised_irqs : std_logic_vector(p_irq_count-1 downto 0);	-- detected edges
	signal s_servicing_irqs : std_logic_vector(p_irq_count-1 downto 0);	-- irqs currently being serviced
	constant c_zero_bits : std_logic_vector(p_irq_count-1 downto 0) := (others => '0');
begin

	-- Output signals
	o_hijacked <= s_hijacked;
	o_is_ic_port <= s_is_ic_port;
	o_nmi_n <= s_nmi_n;

	-- Generate NMI when any irq lines are active
	s_nmi_n <= '0' when s_hijacked = '0' and s_raised_irqs /= c_zero_bits else '1';

	-- Is Interrupt Controller Port?
	s_is_ic_port <= s_hijacked when i_cpu_addr(7 downto 0) = x"1c" else '0';

	-- Reading from IC port, returns the current IRQs being services
	o_cpu_din(p_irq_count-1 downto 0) <= s_servicing_irqs;
	o_cpu_din(7 downto p_irq_count) <= (others => '0');

	port_handler : process(i_clock)
	begin
		if rising_edge(i_clock) then
			if i_reset = '1' then

				s_hijacked <= '1';
				s_exit_hijack_mode <= '0';
				s_prev_irqs <= (others => '1');

			elsif i_clken = '1' then

				-- Capture rising edges on irq lines
				s_prev_irqs <= i_irqs;
				s_raised_irqs <= s_raised_irqs or (not s_prev_irqs and i_irqs);

				if s_hijacked = '1' then

					-- Handle writes to the interrupt controller port
					if s_is_ic_port = '1' and i_cpu_port_wr='1' then
						s_exit_hijack_mode <= '1';
					end if;

					-- Handle exiting hijack mode
					-- Wait until the CPU is about to execute a RET or RETN instruction 
					-- before actually switching back.
					-- To exit PCU mode:
					--      OUT	(1ch),0x01
					--      RETN or RET
					-- RETN instruction = ED 45 - (just look for the 45)
					-- JP (HL) instruction = E9
					if s_exit_hijack_mode = '1' and (i_cpu_din = x"45" or i_cpu_din = x"E9") and i_cpu_wait_n = '1' then
						s_hijacked <= '0';
						s_exit_hijack_mode <= '0';
					end if; 

				else


					-- Detect the CPU about to execute the NMI by reading instruction
					-- at address 0x0066 and when detected, switch to hijack mode.
					if i_cpu_m1_n = '0' and s_nmi_n = '0' and i_cpu_addr = x"0066" then

						s_hijacked <= '1';
						s_exit_hijack_mode <= '0';

						-- Capture the ireqs we're about to service
						s_servicing_irqs <= s_raised_irqs or (not s_prev_irqs and i_irqs);

						-- And clear the raised ones
						s_raised_irqs <= (others => '0');

					end if;

				end if;

			end if;
		end if;
	end process;

end Behavioral;
