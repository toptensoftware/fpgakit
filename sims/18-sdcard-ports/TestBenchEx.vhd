library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity TestBench is
end TestBench;

architecture behavior of TestBenchEx is
    constant c_clock_hz : real := 100_000_000.0;
    signal s_clock : std_logic := '0';
    signal s_reset : std_logic;

	signal s_sd_status : std_logic_vector(7 downto 0);
	signal s_sd_op_write : std_logic;
	signal s_sd_op_cmd : std_logic_vector(1 downto 0);
	signal s_sd_op_block_number : std_logic_vector(31 downto 0);
	signal s_sd_data_start : std_logic;
	signal s_sd_data_cycle : std_logic;
	signal s_sd_din : std_logic_vector(7 downto 0);
	signal s_sd_dout : std_logic_vector(7 downto 0);

	signal s_arb_request : std_logic_vector(1 downto 0);
	signal s_arb_granted : std_logic_vector(1 downto 0);

	-- Port A
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

    signal s_status_a : std_logic_vector(7 downto 0);
	signal s_op_write_a : std_logic;
	signal s_op_cmd_a : std_logic_vector(1 downto 0);
	signal s_op_block_number_a : std_logic_vector(31 downto 0);
	signal s_data_start_a : std_logic;
	signal s_data_cycle_a : std_logic;
	signal s_din_a : std_logic_vector(7 downto 0);
	signal s_dout_a : std_logic_vector(7 downto 0);

	-- Port B
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

    signal s_status_b : std_logic_vector(7 downto 0);
	signal s_op_write_b : std_logic;
	signal s_op_cmd_b : std_logic_vector(1 downto 0);
	signal s_op_block_number_b : std_logic_vector(31 downto 0);
	signal s_data_start_b : std_logic;
	signal s_data_cycle_b : std_logic;
	signal s_din_b : std_logic_vector(7 downto 0);
	signal s_dout_b : std_logic_vector(7 downto 0);

    signal s_state_a : integer range 0 to 1023;
    signal s_state_b : integer range 0 to 1023;
begin

    reset_proc: process
    begin
        s_reset <= '1';
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

	sdcard : entity work.FakeSDCardController
	port map
	(
		i_reset => s_reset,
		i_clock => s_clock,
		o_status => s_sd_status,
		i_op_write => s_sd_op_write,
		i_op_cmd => s_sd_op_cmd,
		i_op_block_number => s_sd_op_block_number,
		o_data_start => s_sd_data_start,
		o_data_cycle => s_sd_data_cycle,
		i_din => s_sd_din,
		o_dout => s_sd_dout
	);


	s_sd_op_write <= 
		s_sd_op_write_a when s_arb_granted(0) = '1' else 
		s_sd_op_write_b when s_arb_granted(1) = '1' else
		'0';

	s_sd_op_cmd <= 
		s_sd_op_cmd_a when s_arb_granted(0) = '1' else	
		s_sd_op_cmd_b;

	s_sd_op_block_number <= 
		s_sd_op_block_number_a when s_arb_granted(0) = '1' else
		s_sd_op_block_number_b;

	s_sd_din <= 
		s_sd_din_a when s_arb_granted(0) = '1' else
		s_sd_din_b;

	s_sd_status_a <= s_sd_status;
	s_sd_data_start_a <= s_sd_data_start;
	s_sd_data_cycle_a <= s_sd_data_cycle;
	s_sd_dout_a <= s_sd_dout;

	s_sd_status_b <= s_sd_status;
	s_sd_data_start_b <= s_sd_data_start;
	s_sd_data_cycle_b <= s_sd_data_cycle;
	s_sd_dout_b <= s_sd_dout;

	e_PriorityArbiter : entity work.PriorityArbiter
	generic map
	(
		p_signal_count => 2
	)
	port map
	(
		i_clock => s_clock,
		i_clken => '1',
		i_reset => s_reset,
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
		i_reset => s_reset,
		i_clock => s_clock,
		
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

        o_status => s_status_a,
		i_op_write => s_op_write_a,
		i_op_cmd => s_op_cmd_a,
		i_op_block_number => s_op_block_number_a,
		o_data_start => s_data_start_a,
		o_data_cycle => s_data_cycle_a,
		i_din => s_din_a,
		o_dout => s_dout_a
	);



	port_b : entity work.SDCardControllerPort
	port map
	(
		i_reset => s_reset,
		i_clock => s_clock,
		
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

        o_status => s_status_b,
		i_op_write => s_op_write_b,
		i_op_cmd => s_op_cmd_b,
		i_op_block_number => s_op_block_number_b,
		o_data_start => s_data_start_b,
		o_data_cycle => s_data_cycle_b,
		i_din => s_din_b,
		o_dout => s_dout_b
	);



    traffic_a : process(s_clock)
    begin
        if rising_edge(s_clock) then
            if s_reset = '1' then
                s_op_write_a <= '0';
                s_op_cmd_a <= "00";
                s_op_block_number_a <= x"0000AAAA";
                s_din_a <= x"DA";
                s_state_a <= 0;
            else
            
                s_op_write_a <= '0'; 

                case s_state_a is

                    when 0 => 
                        -- Wait for SD card to become ready
                        if s_status_a(0) = '0' then
                            s_state_a <= 1;
                        end if;

                    when 10 =>
                        s_op_cmd_a <= "01";
                        s_op_write_a <= '1';  
                        s_state_a <= 11;

                    when 11 =>
                        if s_data_start_a = '1' then
                            s_state_a <= 12;
                        end if;
                    
                    when 12 =>
                        if s_status_a(0) = '0' then
                            s_state_a <= 13;
                        end if;

                    when 13 => 
                        null;

                    when others => null;
                        if s_state_a < 1023 then
                            s_state_a <= s_state_a + 1;
                        end if;

                end case;
            end if;
        end if;
    end process;

    traffic_b : process(s_clock)
    begin
        if rising_edge(s_clock) then
            if s_reset = '1' then
                s_op_write_b <= '0';
                s_op_cmd_b <= "00";
                s_op_block_number_b <= x"0000BBBB";
                s_din_b <= x"DB";
                s_state_b <= 0;
            else
            
                s_op_write_b <= '0'; 

                case s_state_b is

                    when 0 => 
                        -- Wait for SD card to become ready
                        if s_status_b(0) = '0' then
                            s_state_b <= 1;
                        end if;

                    when 10 =>
                        s_op_cmd_b <= "01";
                        s_op_write_b <= '1';  
                        s_state_b <= 11;

                    when 11 =>
                        if s_data_start_b = '1' then
                            s_state_b <= 12;
                        end if;
                    
                    when 12 =>
                        if s_status_b(0) = '0' then
                            s_state_b <= 13;
                        end if;

                    when 13 => 
                        null;

                    when others => null;
                        if s_state_b < 1023 then
                            s_state_b <= s_state_b + 1;
                        end if;

                end case;
            end if;
        end if;
    end process;

end;