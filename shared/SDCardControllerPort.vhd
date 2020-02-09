--------------------------------------------------------------------------
--
-- SDCardControllerPort Multi-Port
--
-- Provide multiple port access to an SD Card Controller
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity SDCardControllerPort is
port 
(
	-- Clocking
	i_reset : in std_logic;
	i_clock : in std_logic;

	-- Connect to arbiter
	o_sd_request : out std_logic;
	i_sd_granted : in std_logic;

	-- Connect to SDCardController
	i_sd_status : in std_logic_vector(7 downto 0);
	o_sd_op_write : out std_logic;
	o_sd_op_cmd : out std_logic_vector(1 downto 0);
	o_sd_op_block_number : out std_logic_vector(31 downto 0);
	i_sd_data_start : in std_logic;
	i_sd_data_cycle : in std_logic;
	o_sd_din : out std_logic_vector(7 downto 0);
	i_sd_dout : in std_logic_vector(7 downto 0);

	-- Client Port
	o_status : out std_logic_vector(7 downto 0);
	i_op_write : in std_logic;
	i_op_cmd : in std_logic_vector(1 downto 0);
	i_op_block_number : in std_logic_vector(31 downto 0);
	o_data_start : out std_logic;
	o_data_cycle : out std_logic;
	i_din : in std_logic_vector(7 downto 0);
	o_dout : out std_logic_vector(7 downto 0)
);
end SDCardControllerPort;

architecture Behavioral of SDCardControllerPort is
	signal s_op_write : std_logic;
	signal s_op_cmd : std_logic_vector(1 downto 0);
	signal s_op_block_number : std_logic_vector(31 downto 0);
	signal s_status_error : std_logic;
	type state is
	(
		state_idle,
		state_waiting_grant,
		state_waiting_sd,
		state_delay_1,
		state_busy
	);
	signal s_state : state := state_idle;
begin

	-- Request the SD card whenever not idle
	o_sd_request <= '0' when s_state = state_idle else '1';

	-- Map status from controller to client
	o_status(7 downto 4) <= i_sd_status(7 downto 4);
	o_status(3) <= s_status_error;
	o_status(2 downto 1) <= "00" when s_state = state_idle else s_op_cmd;
	o_status(0) <= '0' when s_state = state_idle else '1';

	-- Forward data signals from client
	o_data_start <= '0' when i_sd_granted = '0' else i_sd_data_start;
	o_data_cycle <= '0' when i_sd_granted = '0' else i_sd_data_cycle;
	o_dout <= i_sd_dout;
	
	-- Forward the requested commands
	o_sd_op_write <= s_op_write;
	o_sd_op_cmd <= s_op_cmd;
	o_sd_op_block_number <= s_op_block_number;

	-- Forward incoming data to SD controller
	o_sd_din <= i_din;

	-- State machine
	exec : process(i_clock)
	begin
		if rising_edge(i_clock) then
			if i_reset = '1' then
				s_state <= state_idle;
				s_status_error <= '0';
				s_op_write <= '0';
				s_op_cmd <= (others => '0');
				s_op_block_number <= (others => '0');
			else

				s_op_write <= '0';

				case s_state is

					when state_idle =>
						if i_op_write = '1' then
							s_op_cmd <= i_op_cmd;
							s_op_block_number <= i_op_block_number;
							s_state <= state_waiting_grant;
							s_status_error <= '0';
						end if;

					when state_waiting_grant =>
						if i_sd_granted = '1' then
							s_state <= state_waiting_sd;
						end if;

					when state_waiting_sd => 
						if i_sd_status(0) = '0' then
							s_state <= state_delay_1;
							s_op_write <= '1';
						end if;

					when state_delay_1 =>
						s_state <= state_busy;

					when state_busy =>
						if i_sd_status(0) = '0' then
							s_state <= state_idle;
							s_status_error <= i_sd_status(3);
						end if;

				end case;

			end if;
		end if;
	end process;
		
end Behavioral;


