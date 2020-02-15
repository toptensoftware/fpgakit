--------------------------------------------------------------------------
--
-- SDCardControllerDualPort
--
-- Dual Port SD Card Controller
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity SDCardControllerDualPort is
generic
(
	p_clock_div_800khz : integer;
	p_clock_div_50mhz : integer;
	p_use_fake_sd_card_controller : boolean := false
);
port 
(
	-- Clocking
	i_reset : in std_logic;
	i_clock : in std_logic;

	-- SD Card Signals
	o_ss_n : out std_logic;
	o_mosi : out std_logic;
	i_miso : in std_logic;
	o_sclk : out std_logic;

	-- o_status signals
	o_status : out std_logic_vector(7 downto 0);
	o_last_block_number : out std_logic_vector(31 downto 0);

	-- Port A
	o_status_a : out std_logic_vector(7 downto 0);
	i_op_write_a : in std_logic;
	i_op_cmd_a : in std_logic_vector(1 downto 0);
	i_op_block_number_a : in std_logic_vector(31 downto 0);
	o_data_start_a : out std_logic;
	o_data_cycle_a : out std_logic;
	i_din_a : in std_logic_vector(7 downto 0);
	o_dout_a : out std_logic_vector(7 downto 0);

	-- Port B
	o_status_b : out std_logic_vector(7 downto 0);
	i_op_write_b : in std_logic;
	i_op_cmd_b : in std_logic_vector(1 downto 0);
	i_op_block_number_b : in std_logic_vector(31 downto 0);
	o_data_start_b : out std_logic;
	o_data_cycle_b : out std_logic;
	i_din_b : in std_logic_vector(7 downto 0);
	o_dout_b : out std_logic_vector(7 downto 0)
);
end SDCardControllerDualPort;

architecture Behavioral of SDCardControllerDualPort is

	signal s_sd_status : std_logic_vector(7 downto 0);
	signal s_op_write : std_logic;
	signal s_op_cmd : std_logic_vector(1 downto 0);
	signal s_op_block_number : std_logic_vector(31 downto 0);
	signal s_data_start : std_logic;
	signal s_data_cycle : std_logic;
	signal s_din : std_logic_vector(7 downto 0);
	signal s_dout : std_logic_vector(7 downto 0);

	signal s_arb_request : std_logic_vector(1 downto 0);
	signal s_arb_granted : std_logic_vector(1 downto 0);

	signal s_sd_request_a : std_logic;
	signal s_sd_granted_a : std_logic;
	signal s_sd_status_a : std_logic_vector(7 downto 0);
	signal s_sd_op_write_a : std_logic;
	signal s_sd_op_cmd_a : std_logic_vector(1 downto 0);
	signal s_sd_op_block_number_a : std_logic_vector(31 downto 0);
	signal s_sd_data_start_a : std_logic;
	signal s_sd_data_cycle_a : std_logic;
	signal s_sd_din_a : std_logic_vector(7 downto 0);
	signal s_sd_dout_a : std_logic_vector(7 downto 0);

	signal s_sd_request_b : std_logic;
	signal s_sd_granted_b : std_logic;
	signal s_sd_status_b : std_logic_vector(7 downto 0);
	signal s_sd_op_write_b : std_logic;
	signal s_sd_op_cmd_b : std_logic_vector(1 downto 0);
	signal s_sd_op_block_number_b : std_logic_vector(31 downto 0);
	signal s_sd_data_start_b : std_logic;
	signal s_sd_data_cycle_b : std_logic;
	signal s_sd_din_b : std_logic_vector(7 downto 0);
	signal s_sd_dout_b : std_logic_vector(7 downto 0);

	signal s_din_b : std_logic_vector(7 downto 0);
	signal s_dout_b : std_logic_vector(7 downto 0);

begin

	o_status <= s_sd_status;

	without_fake : if not p_use_fake_sd_card_controller generate

		e_SDCardController : entity work.SDCardController
		generic map
		(
			p_clock_div_800khz => p_clock_div_800khz,
			p_clock_div_50mhz => p_clock_div_50mhz
		)
		port map
		(
			i_reset => i_reset,
			i_clock => i_clock,
			
			o_ss_n => o_ss_n,
			o_mosi => o_mosi,
			i_miso => i_miso,
			o_sclk => o_sclk,
			
			o_status => s_sd_status,
			o_last_block_number => o_last_block_number,

			i_op_write => s_op_write,
			i_op_cmd => s_op_cmd,
			i_op_block_number => s_op_block_number,
			o_data_start => s_data_start,
			o_data_cycle => s_data_cycle,
			i_din => s_din,
			o_dout => s_dout
		);
	end generate;

	with_fake : if p_use_fake_sd_card_controller generate

		e_fake_SDCardController : entity work.FakeSDCardController
		port map
		(
			i_reset => i_reset,
			i_clock => i_clock,
			o_status => s_sd_status,
			i_op_write => s_op_write,
			i_op_cmd => s_op_cmd,
			i_op_block_number => s_op_block_number,
			o_data_start => s_data_start,
			o_data_cycle => s_data_cycle,
			i_din => s_din,
			o_dout => s_dout
		);

		o_last_block_number <= x"DEADBEEF";

		o_ss_n <= '1';
		o_mosi <= '1';
		o_sclk <= '1';

	end generate;

	s_op_write <= 
		s_sd_op_write_a when s_arb_granted(0) = '1' else 
		s_sd_op_write_b when s_arb_granted(1) = '1' else
		'0';

	s_op_cmd <= 
		s_sd_op_cmd_a when s_arb_granted(0) = '1' else	
		s_sd_op_cmd_b;

	s_op_block_number <= 
		s_sd_op_block_number_a when s_arb_granted(0) = '1' else
		s_sd_op_block_number_b;

	s_din <= 
		s_sd_din_a when s_arb_granted(0) = '1' else
		s_sd_din_b;

	s_sd_status_a <= s_sd_status;
	s_sd_data_start_a <= s_data_start;
	s_sd_data_cycle_a <= s_data_cycle;
	s_sd_dout_a <= s_dout;

	s_sd_status_b <= s_sd_status;
	s_sd_data_start_b <= s_data_start;
	s_sd_data_cycle_b <= s_data_cycle;
	s_sd_dout_b <= s_dout;

	e_PriorityArbiter : entity work.PriorityArbiter
	generic map
	(
		p_signal_count => 2
	)
	port map
	(
		i_clock => i_clock,
		i_clken => '1',
		i_reset => i_reset,
		i_request => s_arb_request,
		o_granted => s_arb_granted
	);

	s_arb_request(0) <= s_sd_request_a;
	s_arb_request(1) <= s_sd_request_b;
	s_sd_granted_a <= s_arb_granted(0);
	s_sd_granted_b <= s_arb_granted(1);



	port_a : entity work.SDCardControllerPort
	port map
	(
		i_reset => i_reset,
		i_clock => i_clock,
		
		o_sd_request => s_sd_request_a,
		i_sd_granted => s_sd_granted_a,
		i_sd_status => s_sd_status_a,
		o_sd_op_write => s_sd_op_write_a,
		o_sd_op_cmd => s_sd_op_cmd_a,
		o_sd_op_block_number => s_sd_op_block_number_a,
		i_sd_data_start => s_sd_data_start_a,
		i_sd_data_cycle => s_sd_data_cycle_a,
		o_sd_din => s_sd_din_a,
		i_sd_dout => s_sd_dout_a,

		o_status => o_status_a,
		i_op_write => i_op_write_a,
		i_op_cmd => i_op_cmd_a,
		i_op_block_number => i_op_block_number_a,
		o_data_start => o_data_start_a,
		o_data_cycle => o_data_cycle_a,
		i_din => i_din_a,
		o_dout => o_dout_a
	);



	port_b : entity work.SDCardControllerPort
	port map
	(
		i_reset => i_reset,
		i_clock => i_clock,
		
		o_sd_request => s_sd_request_b,
		i_sd_granted => s_sd_granted_b,
		i_sd_status => s_sd_status_b,
		o_sd_op_write => s_sd_op_write_b,
		o_sd_op_cmd => s_sd_op_cmd_b,
		o_sd_op_block_number => s_sd_op_block_number_b,
		i_sd_data_start => s_sd_data_start_b,
		i_sd_data_cycle => s_sd_data_cycle_b,
		o_sd_din => s_sd_din_b,
		i_sd_dout => s_sd_dout_b,

		o_status => o_status_b,
		i_op_write => i_op_write_b,
		i_op_cmd => i_op_cmd_b,
		i_op_block_number => i_op_block_number_b,
		o_data_start => o_data_start_b,
		o_data_cycle => o_data_cycle_b,
		i_din => s_din_b,
		o_dout => s_dout_b
	);

	s_din_b <= i_din_b;
	o_dout_b <= s_dout_b;

end Behavioral;


