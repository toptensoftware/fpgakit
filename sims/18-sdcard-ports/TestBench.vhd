library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity TestBench is
end TestBench;

architecture behavior of TestBench is
    constant c_clock_hz : real := 100_000_000.0;
    signal s_clock : std_logic := '0';
    signal s_reset : std_logic;

	-- Port A
    signal s_status_a : std_logic_vector(7 downto 0);
	signal s_op_write_a : std_logic;
	signal s_op_cmd_a : std_logic_vector(1 downto 0);
	signal s_op_block_number_a : std_logic_vector(31 downto 0);
	signal s_data_start_a : std_logic;
	signal s_data_cycle_a : std_logic;
	signal s_din_a : std_logic_vector(7 downto 0);
	signal s_dout_a : std_logic_vector(7 downto 0);

	-- Port B
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


	e_SDCardControllerDualPort : entity work.SDCardControllerDualPort
	generic map
	(
		p_clock_div_800khz => 1,
		p_clock_div_50mhz => 1,
		p_use_fake_sd_card_controller => true
	)
	port map
	(
		i_reset => s_reset,
		i_clock => s_clock,

		o_ss_n => open,
		o_mosi => open,
		i_miso => '1',
		o_sclk => open,
        
		o_status => open,
		o_last_block_number => open,

        o_status_a => s_status_a,
		i_op_write_a => s_op_write_a,
		i_op_cmd_a => s_op_cmd_a,
		i_op_block_number_a => s_op_block_number_a,
		o_data_start_a => s_data_start_a,
		o_data_cycle_a => s_data_cycle_a,
		i_din_a => s_din_a,
		o_dout_a => s_dout_a,
		
        o_status_b => s_status_b,
        i_op_write_b => s_op_write_b,
		i_op_cmd_b => s_op_cmd_b,
		i_op_block_number_b => s_op_block_number_b,
		o_data_start_b => s_data_start_b,
		o_data_cycle_b => s_data_cycle_b,
		i_din_b => s_din_b,
		o_dout_b => s_dout_b
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

                    when 11 =>
                        s_op_cmd_a <= "01";
                        s_op_write_a <= '1';  
                        s_state_a <= 11;

                    when 12 =>
                        if s_data_start_a = '1' then
                            s_state_a <= 12;
                        end if;
                    
                    when 13 =>
                        if s_status_a(0) = '0' then
                            s_state_a <= 13;
                        end if;

                    when 14 => 
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