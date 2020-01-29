--------------------------------------------------------------------------
--
-- SimpleRamInterface
--
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use work.FunctionLib.all;

entity SimpleRamInterface is
port 
( 
    i_clock : in std_logic;                 -- Clock
    i_clken : in std_logic;
    i_reset : in std_logic;                 -- Reset (synchronous, active high)

    -- Simple read/write single byte interface
    i_wr : in std_logic;
    i_cs : in std_logic;
    i_addr : in std_logic_vector(29 downto 0);
    i_data : in std_logic_vector(7 downto 0);
    o_data : out std_logic_vector(7 downto 0);
    o_wait : out std_logic;

    -- Folded MIG bus
    mig_xrx : in std_logic_vector(56 downto 0);
    mig_xtx : out std_logic_vector(80 downto 0)
);
end SimpleRamInterface;

architecture Behavioral of SimpleRamInterface is
    signal mig_port_calib_done                        : std_logic;
    signal mig_port_cmd_clk                           : std_logic;
    signal mig_port_cmd_en                            : std_logic;
    signal mig_port_cmd_instr                         : std_logic_vector(2 downto 0);
    signal mig_port_cmd_bl                            : std_logic_vector(5 downto 0);
    signal mig_port_cmd_byte_addr                     : std_logic_vector(29 downto 0);
    signal mig_port_cmd_empty                         : std_logic;
    signal mig_port_cmd_full                          : std_logic;
    signal mig_port_wr_clk                            : std_logic;
    signal mig_port_wr_en                             : std_logic;
    signal mig_port_wr_mask                           : std_logic_vector(3 downto 0);
    signal mig_port_wr_data                           : std_logic_vector(31 downto 0);
    signal mig_port_wr_full                           : std_logic;
    signal mig_port_wr_empty                          : std_logic;
    signal mig_port_wr_count                          : std_logic_vector(6 downto 0);
    signal mig_port_wr_underrun                       : std_logic;
    signal mig_port_wr_error                          : std_logic;
    signal mig_port_rd_clk                            : std_logic;
    signal mig_port_rd_en                             : std_logic;
    signal mig_port_rd_data                           : std_logic_vector(31 downto 0);
    signal mig_port_rd_full                           : std_logic;
    signal mig_port_rd_empty                          : std_logic;
    signal mig_port_rd_count                          : std_logic_vector(6 downto 0);
    signal mig_port_rd_overflow                       : std_logic;
    signal mig_port_rd_error                          : std_logic;
begin

sri : entity work.SimpleRamInterfaceUnfolded
port map
( 
    i_clock => i_clock,
    i_clken => i_clken,
    i_reset => i_reset,
    i_cs => i_cs,
    i_wr => i_wr,
    i_addr => i_addr,
    i_data => i_data,
    o_data => o_data,
    o_wait => o_wait,
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

unfold : entity work.MigPort32Unfold
port map
( 
    mig_xtx => mig_xtx,
    mig_xrx => mig_xrx,
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

end Behavioral;


