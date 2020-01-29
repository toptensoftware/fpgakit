library ieee;
use IEEE.numeric_std.all;
use ieee.std_logic_1164.all;

entity TestBench is
end TestBench;

architecture behavior of TestBench is
    constant c_clock_hz : real := 10_000_000.0;
    signal s_clock : std_logic := '0';
    signal s_clken : std_logic := '0';
    signal s_reset : std_logic;

    signal s_sri_wr : std_logic;
    signal s_sri_cs : std_logic;
    signal s_sri_addr : std_logic_vector(29 downto 0);
    signal s_sri_addr16 : std_logic_vector(15 downto 0);
    signal s_sri_din : std_logic_vector(7 downto 0);
    signal s_sri_dout : std_logic_vector(7 downto 0);
    signal s_sri_wait : std_logic;

	signal mig_port_calib_done 						  : std_logic;
    signal mig_port_cmd_clk                           : std_logic;
    signal mig_port_wr_clk                           : std_logic;
    signal mig_port_rd_clk                           : std_logic;
    signal mig_port_cmd_en                            : std_logic;
    signal mig_port_cmd_instr                         : std_logic_vector(2 downto 0);
    signal mig_port_cmd_bl                            : std_logic_vector(5 downto 0);
    signal mig_port_cmd_byte_addr                     : std_logic_vector(29 downto 0);
    signal mig_port_cmd_empty                         : std_logic;
    signal mig_port_cmd_full                          : std_logic;
    signal mig_port_wr_en                             : std_logic;
    signal mig_port_wr_mask                           : std_logic_vector(3 downto 0);
    signal mig_port_wr_data                           : std_logic_vector(31 downto 0);
    signal mig_port_wr_full                           : std_logic;
    signal mig_port_wr_empty                          : std_logic;
    signal mig_port_wr_count                          : std_logic_vector(6 downto 0);
    signal mig_port_wr_underrun                       : std_logic;
    signal mig_port_wr_error                          : std_logic;
    signal mig_port_rd_en                             : std_logic;
    signal mig_port_rd_data                           : std_logic_vector(31 downto 0);
    signal mig_port_rd_full                           : std_logic;
    signal mig_port_rd_empty                          : std_logic;
    signal mig_port_rd_count                          : std_logic_vector(6 downto 0);
    signal mig_port_rd_overflow                       : std_logic;
    signal mig_port_rd_error                          : std_logic;

	signal s_state : integer range 0 to 15;

begin

    reset_proc: process
    begin
        s_reset <= '1';
        wait until falling_edge(s_clock);
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

    div : entity work.ClockDivider
    generic map
    (
        p_period => 20
    )
    port map
    ( 
        i_clock => s_clock,
        i_clken => '1',
        i_reset => s_reset,
        o_clken => s_clken
    );


    mig : entity work.FakeMigPort
    port map
    ( 
        i_reset => s_reset,
        mig_port_calib_done => mig_port_calib_done,
        mig_port_cmd_clk => mig_port_cmd_clk,
        mig_port_cmd_en => mig_port_cmd_en,
        mig_port_cmd_instr => mig_port_cmd_instr,
        mig_port_cmd_bl => mig_port_cmd_bl,
        mig_port_cmd_byte_addr => mig_port_cmd_byte_addr,
        mig_port_cmd_empty => mig_port_cmd_empty,
        mig_port_cmd_full => mig_port_cmd_full,
        mig_port_wr_clk => mig_port_wr_clk,
        mig_port_wr_en => mig_port_wr_en,
        mig_port_wr_mask => mig_port_wr_mask,
        mig_port_wr_data => mig_port_wr_data,
        mig_port_wr_full => mig_port_wr_full,
        mig_port_wr_empty => mig_port_wr_empty,
        mig_port_wr_count => mig_port_wr_count,
        mig_port_wr_underrun => mig_port_wr_underrun,
        mig_port_wr_error => mig_port_wr_error,
        mig_port_rd_clk => mig_port_rd_clk,
        mig_port_rd_en => mig_port_rd_en,
        mig_port_rd_data => mig_port_rd_data,
        mig_port_rd_full => mig_port_rd_full,
        mig_port_rd_empty => mig_port_rd_empty,
        mig_port_rd_count => mig_port_rd_count,
        mig_port_rd_overflow => mig_port_rd_overflow,
        mig_port_rd_error => mig_port_rd_error
    );

    sri : entity work.SimpleRamInterfaceUnfolded
    port map
    ( 
        i_clock => s_clock,
        i_clken => s_clken,
        i_reset => s_reset,
        i_wr => s_sri_wr,
        i_cs => s_sri_cs,
        i_addr => s_sri_addr,
        i_data => s_sri_din,
        o_data => s_sri_dout,
        o_wait => s_sri_wait,
        mig_port_calib_done => mig_port_calib_done,
        mig_port_cmd_clk => mig_port_cmd_clk,
        mig_port_cmd_en => mig_port_cmd_en,
        mig_port_cmd_instr => mig_port_cmd_instr,
        mig_port_cmd_bl => mig_port_cmd_bl,
        mig_port_cmd_byte_addr => mig_port_cmd_byte_addr,
        mig_port_cmd_empty => mig_port_cmd_empty,
        mig_port_cmd_full => mig_port_cmd_full,
        mig_port_wr_clk => mig_port_wr_clk,
        mig_port_wr_en => mig_port_wr_en,
        mig_port_wr_mask => mig_port_wr_mask,
        mig_port_wr_data => mig_port_wr_data,
        mig_port_wr_full => mig_port_wr_full,
        mig_port_wr_empty => mig_port_wr_empty,
        mig_port_wr_count => mig_port_wr_count,
        mig_port_wr_underrun => mig_port_wr_underrun,
        mig_port_wr_error => mig_port_wr_error,
        mig_port_rd_clk => mig_port_rd_clk,
        mig_port_rd_en => mig_port_rd_en,
        mig_port_rd_data => mig_port_rd_data,
        mig_port_rd_full => mig_port_rd_full,
        mig_port_rd_empty => mig_port_rd_empty,
        mig_port_rd_count => mig_port_rd_count,
        mig_port_rd_overflow => mig_port_rd_overflow,
        mig_port_rd_error => mig_port_rd_error
    );

    s_sri_addr <= "00000000000000" & s_sri_addr16;

    traffic : process(s_clock)
    begin
        if rising_edge(s_clock) then
            if s_reset = '1' then
                s_sri_wr <= '0';
                s_sri_cs <= '1';
                s_sri_addr16 <= (others => '0');
                s_sri_din <= (others => '0');
                s_state <= 0;
            elsif (s_clken = '1') then
                s_sri_wr <= '0';
                case s_state is

                    when 0 => 
                        if s_sri_wait = '0' then
									s_sri_wr <= '1';
									s_sri_addr16 <= (others => '0');
									s_sri_din <= x"A6";
									s_state <= 1;
								end if;

                    when 1 =>
                        if s_sri_wait = '0' then
                            s_state <= 2;
                        end if;

                    when 2 => 
                        s_sri_addr16 <= x"0001";
                        s_state <= 3;

                    when 3 => 
                        s_sri_addr16 <= x"0010";
                        s_state <= 4;

                    when 4 =>
                        s_sri_addr16 <= x"0001";
                        s_state <= 5;

                    when others =>
                        s_sri_addr16 <= x"0000";

                end case;
            end if;
        end if;
    end process;


end;
