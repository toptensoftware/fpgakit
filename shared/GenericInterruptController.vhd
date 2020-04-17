--------------------------------------------------------------------------
--
-- InterruptController
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

entity GenericInterruptController is
generic
(
	p_irq_count : integer
);
port
(
	-- Clocking
	i_reset : in std_logic;
    i_clock : in std_logic;

	-- When in ISR returns a stable set of raised irq flags
	o_irqs : out std_logic_vector(p_irq_count - 1  downto 0);

	-- From devices raising IRQs
	i_irqs : std_logic_vector(p_irq_count - 1 downto 0);

	-- '1' when interrupt request is pending
	o_irq : out std_logic;

	-- Raise for one cycle on entering ISR (eg: tie to rising edge of port read)
	i_ack : in std_logic
);
end GenericInterruptController;

architecture Behavioral of GenericInterruptController is
	signal s_prev_irqs : std_logic_vector(p_irq_count-1 downto 0);		-- for edge detection
	signal s_pending_irqs : std_logic_vector(p_irq_count-1 downto 0);	-- detected edges
	signal s_current_irqs : std_logic_vector(p_irq_count-1 downto 0);	-- currently servicing irqs
	constant c_zero_bits : std_logic_vector(p_irq_count-1 downto 0) := (others => '0');
begin

	-- Output signals
	o_irq <= '0' when s_pending_irqs /= c_zero_bits else '1';
	o_irqs <= s_current_irqs;

	state_machine : process(i_clock)
	begin
		if rising_edge(i_clock) then
			if i_reset = '1' then

				s_prev_irqs <= (others => '0');
				s_pending_irqs <= (others => '0');
				s_current_irqs <= (others => '0');

			else

				-- For edge detection
				s_prev_irqs <= i_irqs;

				if i_ack = '1' then

					-- On entering the ISR, capture the raised irqs (while being careful not to miss
					-- any raised on this cycle)
					s_current_irqs <= s_pending_irqs or (not s_prev_irqs and i_irqs);

					-- Clear the pending irqs
					s_pending_irqs <= (others => '0');

				else

					-- Capture raised irq edges
					s_pending_irqs <= s_pending_irqs or (not s_prev_irqs and i_irqs);

				end if;

			end if;
		end if;
	end process;

end Behavioral;
