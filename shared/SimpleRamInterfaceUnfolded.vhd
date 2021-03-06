--------------------------------------------------------------------------
--
-- SimpleRamInterfaceUnfolded
--
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use work.FunctionLib.all;

entity SimpleRamInterfaceUnfolded is
port 
( 
    i_clock : in std_logic;                 -- Clock
    i_reset : in std_logic;                 -- Reset (synchronous, active high)

    -- Simple read/write single byte interface
    i_wr : in std_logic;
    i_rd : in std_logic;
    i_addr : in std_logic_vector(29 downto 0);
    i_data : in std_logic_vector(7 downto 0);
    o_data : out std_logic_vector(7 downto 0);
    o_wait : out std_logic;

    -- MCB control signals
    mig_port_calib_done                        : in std_logic;
    mig_port_cmd_clk                           : out std_logic;
    mig_port_cmd_en                            : out std_logic;
    mig_port_cmd_instr                         : out std_logic_vector(2 downto 0);
    mig_port_cmd_bl                            : out std_logic_vector(5 downto 0);
    mig_port_cmd_byte_addr                     : out std_logic_vector(29 downto 0);
    mig_port_cmd_empty                         : in std_logic;
    mig_port_cmd_full                          : in std_logic;
    mig_port_wr_clk                            : out std_logic;
    mig_port_wr_en                             : out std_logic;
    mig_port_wr_mask                           : out std_logic_vector(3 downto 0);
    mig_port_wr_data                           : out std_logic_vector(31 downto 0);
    mig_port_wr_full                           : in std_logic;
    mig_port_wr_empty                          : in std_logic;
    mig_port_wr_count                          : in std_logic_vector(6 downto 0);
    mig_port_wr_underrun                       : in std_logic;
    mig_port_wr_error                          : in std_logic;
    mig_port_rd_clk                            : out std_logic;
    mig_port_rd_en                             : out std_logic;
    mig_port_rd_data                           : in std_logic_vector(31 downto 0);
    mig_port_rd_full                           : in std_logic;
    mig_port_rd_empty                          : in std_logic;
    mig_port_rd_count                          : in std_logic_vector(6 downto 0);
    mig_port_rd_overflow                       : in std_logic;
    mig_port_rd_error                          : in std_logic
);
end SimpleRamInterfaceUnfolded;

architecture Behavioral of SimpleRamInterfaceUnfolded is
	type sri_state is
	(
		state_idle,
        state_write_when_ready,
		state_write_cmd,
        state_read_when_ready,
		state_wait_read
	);

	signal s_state : sri_state := state_idle;
    signal s_current_word : std_logic_vector(31 downto 0);
    signal s_current_addr : std_logic_vector(29 downto 0);
    signal s_wr_mask : std_logic_vector(3 downto 0);
    signal s_updated_current_word : std_logic_vector(31 downto 0);
    signal s_updated_current_byte_0 : std_logic_vector(7 downto 0);
    signal s_updated_current_byte_1 : std_logic_vector(7 downto 0);
    signal s_updated_current_byte_2 : std_logic_vector(7 downto 0);
    signal s_updated_current_byte_3 : std_logic_vector(7 downto 0);
    signal s_is_current_word : std_logic;
    signal s_have_current_word : std_logic;
    signal s_wr_edge : std_logic;
    signal s_rd_edge : std_logic;
begin

    -- Generate wait signal
	o_wait <= '1' when s_state /= state_idle else
                s_wr_edge or s_rd_edge;

    -- MCB address is the byte address with lowest two bits removed
    mig_port_cmd_byte_addr <= i_addr(i_addr'high downto 2) & "00";

    -- We only ever read/write one word
	mig_port_cmd_bl <= "000000";  

    -- Does the input address match the current address (excluding lowest two bits)
    s_is_current_word <= '1' when s_current_addr(29 downto 2) = i_addr(29 downto 2) and s_have_current_word = '1' else '0';

    -- Write byte mapping
    mig_port_wr_data <= i_data & i_data & i_data & i_data;
    mig_port_wr_mask <= s_wr_mask;
    s_wr_mask <=
            "1110" when i_addr(1 downto 0) = "00" else
            "1101" when i_addr(1 downto 0) = "01" else
            "1011" when i_addr(1 downto 0) = "10" else
            "0111";

	e_EdgeDetector_wr : entity work.EdgeDetector
	generic map
	(
		p_default_state => '0',
		p_falling_edge => false,
		p_rising_edge => true,
		p_pulse => '1'
	)
	port map
	(
		i_clock => i_clock,
		i_clken => '1',
		i_reset => i_reset,
		i_signal => i_wr,
		o_pulse => s_wr_edge
	);

	e_EdgeDetector_rd : entity work.EdgeDetector
	generic map
	(
		p_default_state => '0',
		p_falling_edge => false,
		p_rising_edge => true,
		p_pulse => '1'
	)
	port map
	(
		i_clock => i_clock,
		i_clken => '1',
		i_reset => i_reset,
		i_signal => i_rd,
		o_pulse => s_rd_edge
	);

    -- Read byte mapping
    o_data <= 
        s_current_word(7 downto 0) when s_current_addr(1 downto 0) = "00" else
        s_current_word(15 downto 8) when s_current_addr(1 downto 0) = "01" else
        s_current_word(23 downto 16) when s_current_addr(1 downto 0) = "10" else
        s_current_word(31 downto 24);

    -- Work out the new current word value after a write operation
    s_updated_current_byte_0 <= s_current_word(7 downto 0) when s_wr_mask(0) = '1' else i_data;
    s_updated_current_byte_1 <= s_current_word(15 downto 8) when s_wr_mask(1) = '1' else i_data;
    s_updated_current_byte_2 <= s_current_word(23 downto 16) when s_wr_mask(2) = '1' else i_data;
    s_updated_current_byte_3 <= s_current_word(31 downto 24) when s_wr_mask(3) = '1' else i_data;
    s_updated_current_word <= s_updated_current_byte_3 & s_updated_current_byte_2 & s_updated_current_byte_1 & s_updated_current_byte_0;

    -- Forward clock signals
	mig_port_cmd_clk <= i_clock;
	mig_port_wr_clk <= i_clock;
	mig_port_rd_clk <= i_clock;

    -- Main process
	sri : process(i_clock)
	begin
		if rising_edge(i_clock) then
			if i_reset = '1' then
				s_state <= state_idle;
				mig_port_wr_en <= '0';
				mig_port_rd_en <= '0';
				mig_port_cmd_en <= '0';
                s_have_current_word <= '0';
                s_current_addr <= (others => '0');
                s_current_word <= (others => '0');
			else

				mig_port_wr_en <= '0';	
				mig_port_rd_en <= '0';
				mig_port_cmd_en <= '0';

				case s_state is

					when state_idle =>
                        if i_wr = '1' then

                            -- Start write operation
                            if mig_port_calib_done = '1' then
                                s_state <= state_write_cmd;
                                mig_port_wr_en <= '1';
                            else
                                s_state <= state_write_when_ready;
                            end if;

                        elsif i_rd = '1' then

                            -- Start read operation (if necessary)
                            if mig_port_cmd_full = '0' and mig_port_calib_done = '1' then
                                if s_is_current_word = '0' then
                                    -- Read instruction
                                    mig_port_cmd_instr <= "001";
                                    mig_port_cmd_en <= '1';
                                    s_state <= state_wait_read;
                                else
                                    -- Different address in same word
                                    s_current_addr <= i_addr;
                                    s_state <= state_idle;
                                end if;
                            else
                                s_state <= state_read_when_ready;
                            end if;

                        end if;

					when state_write_when_ready =>
						-- Wait for calib before write
					 	if mig_port_calib_done = '1' then
							s_state <= state_write_cmd;
							mig_port_wr_en <= '1';
						end if;

					when state_write_cmd =>
						-- Invoke write
						if mig_port_cmd_full = '0'  then
							mig_port_cmd_instr <= "000";		-- write
							mig_port_cmd_en <= '1';
							s_state <= state_idle;
                            if s_is_current_word = '1' then
                                s_current_word <= s_updated_current_word;
                                s_current_addr <= i_addr;
                            end if;
						end if;

					when state_read_when_ready =>
						if mig_port_cmd_full = '0' and mig_port_calib_done = '1' then
                            if s_is_current_word = '0' then
                                mig_port_cmd_instr <= "001";		-- read
                                mig_port_cmd_en <= '1';
                                s_state <= state_wait_read;
                            else
                                s_current_addr <= i_addr;
                                s_state <= state_idle;
                            end if;
						end if;

					when state_wait_read =>
						if mig_port_rd_empty = '0' then
                            s_current_word <= mig_port_rd_data;
                            s_current_addr <= i_addr;
                            s_have_current_word <= '1';
							mig_port_rd_en <= '1';
							s_state <= state_idle;
						end if;

					when others =>
						null;
				end case;

			end if;
		end if;
	end process;


end Behavioral;


