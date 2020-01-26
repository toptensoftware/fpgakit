library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

entity top is
port 
( 
	-- These signals must match what's in the .ucf file
	i_clock_100mhz : in std_logic;
	i_button_b : in std_logic;

	-- PSX Signals
	o_psx_att : out std_logic;
	o_psx_clock : out std_logic;
	o_psx_hoci : out std_logic;
	i_psx_hico : in std_logic;
	i_psx_ack : in std_logic;

	-- LEDs
	o_leds : out std_logic_vector(7 downto 0)
);
end top;

architecture Behavioral of top is
	signal s_reset : std_logic;
	signal s_connected : std_logic;
	signal s_buttons : std_logic_vector(15 downto 0);
begin

	-- Reset signal
	s_reset <= not i_button_b;

	--                              up             down           left           right          X
	o_leds <= s_connected & "00" & s_buttons(4) & s_buttons(6) & s_buttons(7) & s_buttons(5) & s_buttons(14);

	psxhost : entity work.PsxControllerHost
	generic map
	(
		p_clken_hz => 100_000_000,
		p_poll_hz => 60
	)
	port map
	( 
		i_clock => i_clock_100mhz,
		i_clken => '1',
		i_reset => s_reset,
		o_psx_att => o_psx_att,
		o_psx_clock => o_psx_clock,
		o_psx_hoci => o_psx_hoci,
		i_psx_hico => i_psx_hico,
		i_psx_ack => i_psx_ack,
		o_connected => s_connected,
		o_buttons => s_buttons
	);

end Behavioral;

