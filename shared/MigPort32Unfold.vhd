--------------------------------------------------------------------------
--
-- MigPort32Unfold
--
-- Unfolds a 32-bit Xilinx Mig port into two vector signals
-- for easy mapping and connection
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use work.FunctionLib.all;

entity MigPort32Unfold is
port 
( 
    -- Collapsed Signals
    mig_xrx : in std_logic_vector(56 downto 0);
    mig_xtx : out std_logic_vector(80 downto 0);

    -- Signals to MIG
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
end MigPort32Unfold;

architecture Behavioral of MigPort32Unfold is
begin
    mig_xtx(0)                    <= mig_port_cmd_clk;
    mig_xtx(1)                    <= mig_port_cmd_en;
    mig_xtx(4 downto 2)           <= mig_port_cmd_instr;
    mig_xtx(10 downto 5)          <= mig_port_cmd_bl;
    mig_xtx(40 downto 11)         <= mig_port_cmd_byte_addr;
    mig_xtx(41)                   <= mig_port_wr_clk;
    mig_xtx(42)                   <= mig_port_wr_en;
    mig_xtx(46 downto 43)         <= mig_port_wr_mask;
    mig_xtx(78 downto 47)         <= mig_port_wr_data;
    mig_xtx(79)                   <= mig_port_rd_clk;
    mig_xtx(80)                   <= mig_port_rd_en;

    mig_port_cmd_empty          <= mig_xrx(0);
    mig_port_cmd_full           <= mig_xrx(1);
    mig_port_wr_full            <= mig_xrx(2);
    mig_port_wr_empty           <= mig_xrx(3);
    mig_port_wr_count           <= mig_xrx(10 downto 4) ;
    mig_port_wr_underrun        <= mig_xrx(11);
    mig_port_wr_error           <= mig_xrx(12);
    mig_port_rd_data            <= mig_xrx(44 downto 13);
    mig_port_rd_full            <= mig_xrx(45);
    mig_port_rd_empty           <= mig_xrx(46);
    mig_port_rd_count           <= mig_xrx(53 downto 47);
    mig_port_rd_overflow        <= mig_xrx(54);
    mig_port_rd_error           <= mig_xrx(55);
    mig_port_calib_done         <= mig_xrx(56);

end Behavioral;

