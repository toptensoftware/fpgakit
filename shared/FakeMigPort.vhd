--------------------------------------------------------------------------
--
-- FakeMigPort
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use work.FunctionLib.all;

entity FakeMigPort is
port 
( 
    i_reset : in std_logic;
    mig_port_calib_done                        : out std_logic;
    mig_port_cmd_clk                           : in std_logic;
    mig_port_cmd_en                            : in std_logic;
    mig_port_cmd_instr                         : in std_logic_vector(2 downto 0);
    mig_port_cmd_bl                            : in std_logic_vector(5 downto 0);
    mig_port_cmd_byte_addr                     : in std_logic_vector(29 downto 0);
    mig_port_cmd_empty                         : out std_logic;
    mig_port_cmd_full                          : out std_logic;
    mig_port_wr_clk                            : in std_logic;
    mig_port_wr_en                             : in std_logic;
    mig_port_wr_mask                           : in std_logic_vector(3 downto 0);
    mig_port_wr_data                           : in std_logic_vector(31 downto 0);
    mig_port_wr_full                           : out std_logic;
    mig_port_wr_empty                          : out std_logic;
    mig_port_wr_count                          : out std_logic_vector(6 downto 0);
    mig_port_wr_underrun                       : out std_logic;
    mig_port_wr_error                          : out std_logic;
    mig_port_rd_clk                            : in std_logic;
    mig_port_rd_en                             : in std_logic;
    mig_port_rd_data                           : out std_logic_vector(31 downto 0);
    mig_port_rd_full                           : out std_logic;
    mig_port_rd_empty                          : out std_logic;
    mig_port_rd_count                          : out std_logic_vector(6 downto 0);
    mig_port_rd_overflow                       : out std_logic;
    mig_port_rd_error                          : out std_logic
);
end FakeMigPort;

architecture Behavioral of FakeMigPort is
    -- Calibration
    signal s_calib_done : std_logic := '0';
    signal s_calib_time : integer range 0 to 100 := 0;

    -- Command
    constant c_cmdfifo_width : integer := mig_port_cmd_byte_addr'length + mig_port_cmd_bl'length + mig_port_cmd_instr'length;
    signal s_cmdfifo_wr : std_logic;
    signal s_cmdfifo_rd : std_logic;
    signal s_cmdfifo_din : std_logic_vector(c_cmdfifo_width-1 downto 0);
    signal s_cmdfifo_dout : std_logic_vector(c_cmdfifo_width-1 downto 0);
    signal s_cmdfifo_empty : std_logic;

    -- Write
    constant c_wrfifo_width : integer := mig_port_wr_mask'length + mig_port_wr_data'length;
    signal s_wrfifo_wr : std_logic;
    signal s_wrfifo_rd : std_logic;
    signal s_wrfifo_din : std_logic_vector(c_wrfifo_width-1 downto 0);
    signal s_wrfifo_dout : std_logic_vector(c_wrfifo_width-1 downto 0);
    signal s_wrfifo_empty : std_logic;

    -- Read
    constant c_rdfifo_width : integer := mig_port_rd_data'length;
    signal s_rdfifo_wr : std_logic;
    signal s_rdfifo_din : std_logic_vector(c_rdfifo_width-1 downto 0);

    -- The RAM
    constant c_ram_size : integer := 2 ** 20;
    constant c_bit_width : integer := mig_port_wr_data'length;
	type mem_type is array(0 to c_ram_size-1) of std_logic_vector(31 downto 0);
	shared variable ram : mem_type := (others => x"cccccccc" );

    -- Executor
    signal s_state : integer range 0 to 100;
    signal s_current_cmd_instr : std_logic_vector(2 downto 0);
    signal s_current_cmd_bl : std_logic_vector(5 downto 0);
    signal s_current_cmd_byte_addr : std_logic_vector(29 downto 0);
    signal s_current_wr_mask : std_logic_vector(3 downto 0);
    signal s_current_wr_data : std_logic_vector(31 downto 0);

    signal s_unmasked_word : std_logic_vector(31 downto 0);
    signal s_masked_word : std_logic_vector(31 downto 0);
    signal s_masked_byte_0 : std_logic_vector(7 downto 0);
    signal s_masked_byte_1 : std_logic_vector(7 downto 0);
    signal s_masked_byte_2 : std_logic_vector(7 downto 0);
    signal s_masked_byte_3 : std_logic_vector(7 downto 0);
    signal s_ram_addr : std_logic_vector(29 downto 0);
    signal s_ram_ptr : integer range 0 to c_ram_size-1;
    signal s_delay_count : integer range 0 to 20;

begin

    -- Calibration done initial delay
    mig_port_calib_done <= s_calib_done;
    s_calib_done <= '1' when s_calib_time = 100 else '0';
    calib : process(mig_port_cmd_clk)
    begin
        if rising_edge(mig_port_cmd_clk) then
            if s_calib_done = '0' then
                s_calib_time <= s_calib_time + 1;
            end if;
        end if;
    end process;

    -- Command port
    s_cmdfifo_din <= mig_port_cmd_byte_addr & mig_port_cmd_bl & mig_port_cmd_instr;
    s_cmdfifo_wr <= mig_port_cmd_en;

    mig_port_cmd_empty <= s_cmdfifo_empty;
    cmd_fifo : entity work.Fifo
    generic map
    (
        p_bit_width => c_cmdfifo_width,
        p_addr_width => 3
    )
    port map
    ( 
        i_clock => mig_port_cmd_clk,
        i_clken => s_calib_done,                -- disable until calibration done
        i_reset => i_reset,
        i_write => s_cmdfifo_wr,
        i_data => s_cmdfifo_din,
        i_read => s_cmdfifo_rd,
        o_data => s_cmdfifo_dout,
        o_full => mig_port_cmd_full,
        o_empty => s_cmdfifo_empty,
        o_underflow => open,
        o_overflow => open,
        o_count => open
    );

    -- Write Port
    mig_port_wr_error <= '0';
    s_wrfifo_din <= mig_port_wr_mask & mig_port_wr_data;
    s_wrfifo_wr <= mig_port_wr_en;
    mig_port_wr_empty <= s_wrfifo_empty;
    wr_fifo : entity work.Fifo
    generic map
    (
        p_bit_width => c_wrfifo_width,
        p_addr_width => 6
    )
    port map
    ( 
        i_clock => mig_port_cmd_clk,
        i_clken => s_calib_done,                -- disable until calibration done
        i_reset => i_reset,
        i_write => s_wrfifo_wr,
        i_data => s_wrfifo_din,
        i_read => s_wrfifo_rd,
        o_data => s_wrfifo_dout,
        o_full => mig_port_wr_full,
        o_empty => s_wrfifo_empty,
        o_underflow => mig_port_wr_underrun,
        o_overflow => open,
        o_count => mig_port_wr_count
    );

    -- Read Port
    mig_port_rd_error <= '0';
    rd_fifo : entity work.Fifo
    generic map
    (
        p_bit_width => c_rdfifo_width,
        p_addr_width => 6
    )
    port map
    ( 
        i_clock => mig_port_cmd_clk,
        i_clken => s_calib_done,                -- disable until calibration done
        i_reset => i_reset,
        i_write => s_rdfifo_wr,
        i_data => s_rdfifo_din,
        i_read => mig_port_rd_en,
        o_data => mig_port_rd_data,
        o_full => mig_port_rd_full,
        o_empty => mig_port_rd_empty,
        o_underflow => open,
        o_overflow => mig_port_rd_overflow,
        o_count => mig_port_rd_count
    );

    -- Apply write mask
    s_masked_byte_0 <= s_current_wr_data(7 downto 0) when s_current_wr_mask(0) = '0' else s_unmasked_word(7 downto 0);
    s_masked_byte_1 <= s_current_wr_data(15 downto 8) when s_current_wr_mask(1) = '0' else s_unmasked_word(15 downto 8);
    s_masked_byte_2 <= s_current_wr_data(23 downto 16) when s_current_wr_mask(2) = '0' else s_unmasked_word(23 downto 16);
    s_masked_byte_3 <= s_current_wr_data(31 downto 24) when s_current_wr_mask(3) = '0' else s_unmasked_word(31 downto 24);
    s_masked_word <= s_masked_byte_3 & s_masked_byte_2 & s_masked_byte_1 & s_masked_byte_0;

    -- RAM pointer
    s_ram_addr <= s_current_cmd_byte_addr(29 downto 2) & "00";
    s_ram_ptr <= to_integer(unsigned(s_ram_addr));

    -- Executor process
    exec : process(mig_port_cmd_clk)
    begin
        if rising_edge(mig_port_cmd_clk) then

            if i_reset = '1' then
                s_state <= 0;
                s_cmdfifo_rd <= '0';
                s_wrfifo_rd <= '0';
                s_rdfifo_wr <= '0';
            else

                s_cmdfifo_rd <= '0';
                s_wrfifo_rd <= '0';
                s_rdfifo_wr <= '0';

                case s_state is

                    when 0 =>       -- idle
                        if s_cmdfifo_empty = '0' then
                            s_delay_count <= 0;
                            s_state <= 1;
                        end if;

                    when 1 =>       -- command dequeue delay
                        if s_delay_count = 5 then

                            -- Pull command from queue
                            s_current_cmd_instr <= s_cmdfifo_dout(2 downto 0);
                            s_current_cmd_bl <= s_cmdfifo_dout(8 downto 3);
                            s_current_cmd_byte_addr <= s_cmdfifo_dout(38 downto 9);
                            s_cmdfifo_rd <= '1';

                            -- If have command, start executing it
                            if s_cmdfifo_empty = '1' then
                                s_state <= 0;
                            else
                                s_state <= 2;
                            end if;
                        else
                            s_delay_count <= s_delay_count + 1;
                        end if;

                    when 2 => 

                        s_delay_count <= 0;
                        s_state <= 0;

                        -- Write
                        if s_current_cmd_instr = "000" then
                            s_state <= 10;
                        end if;

                        -- Read
                        if s_current_cmd_instr = "001" then
                            s_state <= 30;
                        end if;


                    when 10 =>
                        -- Pre-write delay
                        if s_delay_count = 5 then
                            s_state <= 11;
                        else
                            s_delay_count <= s_delay_count + 1;
                        end if;

                    when 11 => 

                        -- Write 
                        
                        -- pull data from write fifo
                        s_current_wr_mask <= s_wrfifo_dout(35 downto 32);
                        s_current_wr_data <= s_wrfifo_dout(31 downto 0);
                        s_wrfifo_rd <= '1';
                        if s_wrfifo_empty = '1' then 
                            s_state <= 0;
                        else
                            s_state <= 11;
                        end if;

                        -- Also, get the current word from ram (so we can apply mask)
                        s_unmasked_word <= ram(s_ram_ptr);
                        s_state <= 12;

                    when 12 =>
                        -- Store new word
                        ram(s_ram_ptr) := s_masked_word;

                        -- Back to idle
                        s_state <= 0;

                    when 30 =>
                        -- Pre-read delay
                        if s_delay_count = 5 then
                            s_state <= 31;
                        else
                            s_delay_count <= s_delay_count + 1;
                        end if;

                    when 31 => 
                        -- Get the word from ram
                        s_rdfifo_din <= ram(s_ram_ptr);
                        s_state <= 32;

                    when 32 =>
                        -- Write it to the fifo
                        s_rdfifo_wr <= '1';
                        s_state <= 0;

                    when others =>
                        s_state <= 0;

                end case;

            end if;

        end if;
    end process;


end Behavioral;

