
library ieee;
use ieee.std_logic_1164.all;
entity MimasDualPortSDRAM is
generic
(
    C3_P0_MASK_SIZE         : integer := 4;
    C3_P0_DATA_PORT_SIZE    : integer := 32;
    C3_P1_MASK_SIZE         : integer := 4;
    C3_P1_DATA_PORT_SIZE    : integer := 32;
    C3_MEMCLK_PERIOD        : integer := 10000; 
    C3_RST_ACT_LOW          : integer := 0; 
    C3_INPUT_CLK_TYPE       : string := "SINGLE_ENDED"; 
    C3_CALIB_SOFT_IP        : string := "TRUE"; 
    C3_SIMULATION           : string := "FALSE"; 
    DEBUG_EN                : integer := 0; 
    C3_MEM_ADDR_ORDER       : string := "ROW_BANK_COLUMN"; 
    C3_NUM_DQ_PINS          : integer := 16; 
    C3_MEM_ADDR_WIDTH       : integer := 13; 
    C3_MEM_BANKADDR_WIDTH   : integer := 2 
);
port
(
    -- Connection to MCB
    mcb_xtr : inout  std_logic_vector(18 downto 0);
    mcb_xtx : out std_logic_vector(20 downto 0);
    mcb_xcl : out std_logic_vector(1 downto 0);

    -- System Control Signals
    i_sys_clk : in std_logic;
    i_sys_rst_n : in std_logic;
    o_calib_done : out std_logic;
    o_clk0 : out std_logic;
    o_rst0 : out std_logic;

    -- Port 0
    mig_xtx_p0 : in std_logic_vector(80 downto 0);
    mig_xrx_p0 : out std_logic_vector(56 downto 0);

    -- Port 1
    mig_xtx_p1 : in std_logic_vector(80 downto 0);
    mig_xrx_p1 : out std_logic_vector(56 downto 0)
);
end MimasDualPortSDRAM;

architecture Behavioral of MimasDualPortSDRAM is

   signal c3_p0_cmd_clk                           : std_logic;
   signal c3_p0_cmd_en                            : std_logic;
   signal c3_p0_cmd_instr                         : std_logic_vector(2 downto 0);
   signal c3_p0_cmd_bl                            : std_logic_vector(5 downto 0);
   signal c3_p0_cmd_byte_addr                     : std_logic_vector(29 downto 0);
   signal c3_p0_cmd_empty                         : std_logic;
   signal c3_p0_cmd_full                          : std_logic;
   signal c3_p0_wr_clk                            : std_logic;
   signal c3_p0_wr_en                             : std_logic;
   signal c3_p0_wr_mask                           : std_logic_vector(C3_P0_MASK_SIZE - 1 downto 0);
   signal c3_p0_wr_data                           : std_logic_vector(C3_P0_DATA_PORT_SIZE - 1 downto 0);
   signal c3_p0_wr_full                           : std_logic;
   signal c3_p0_wr_empty                          : std_logic;
   signal c3_p0_wr_count                          : std_logic_vector(6 downto 0);
   signal c3_p0_wr_underrun                       : std_logic;
   signal c3_p0_wr_error                          : std_logic;
   signal c3_p0_rd_clk                            : std_logic;
   signal c3_p0_rd_en                             : std_logic;
   signal c3_p0_rd_data                           : std_logic_vector(C3_P0_DATA_PORT_SIZE - 1 downto 0);
   signal c3_p0_rd_full                           : std_logic;
   signal c3_p0_rd_empty                          : std_logic;
   signal c3_p0_rd_count                          : std_logic_vector(6 downto 0);
   signal c3_p0_rd_overflow                       : std_logic;
   signal c3_p0_rd_error                          : std_logic;
   signal c3_p1_cmd_clk                           : std_logic;
   signal c3_p1_cmd_en                            : std_logic;
   signal c3_p1_cmd_instr                         : std_logic_vector(2 downto 0);
   signal c3_p1_cmd_bl                            : std_logic_vector(5 downto 0);
   signal c3_p1_cmd_byte_addr                     : std_logic_vector(29 downto 0);
   signal c3_p1_cmd_empty                         : std_logic;
   signal c3_p1_cmd_full                          : std_logic;
   signal c3_p1_wr_clk                            : std_logic;
   signal c3_p1_wr_en                             : std_logic;
   signal c3_p1_wr_mask                           : std_logic_vector(C3_P1_MASK_SIZE - 1 downto 0);
   signal c3_p1_wr_data                           : std_logic_vector(C3_P1_DATA_PORT_SIZE - 1 downto 0);
   signal c3_p1_wr_full                           : std_logic;
   signal c3_p1_wr_empty                          : std_logic;
   signal c3_p1_wr_count                          : std_logic_vector(6 downto 0);
   signal c3_p1_wr_underrun                       : std_logic;
   signal c3_p1_wr_error                          : std_logic;
   signal c3_p1_rd_clk                            : std_logic;
   signal c3_p1_rd_en                             : std_logic;
   signal c3_p1_rd_data                           : std_logic_vector(C3_P1_DATA_PORT_SIZE - 1 downto 0);
   signal c3_p1_rd_full                           : std_logic;
   signal c3_p1_rd_empty                          : std_logic;
   signal c3_p1_rd_count                          : std_logic_vector(6 downto 0);
   signal c3_p1_rd_overflow                       : std_logic;
   signal c3_p1_rd_error                          : std_logic;

  signal s_calib_done : std_logic;

begin

  o_calib_done <= s_calib_done;
 
    mig : entity work.MimasDualPortSDRAMUnfolded
    generic map
    (
      C3_P0_MASK_SIZE => C3_P0_MASK_SIZE,
      C3_P0_DATA_PORT_SIZE => C3_P0_DATA_PORT_SIZE,
      C3_P1_MASK_SIZE => C3_P1_MASK_SIZE,
      C3_P1_DATA_PORT_SIZE => C3_P1_DATA_PORT_SIZE,
      C3_MEMCLK_PERIOD => C3_MEMCLK_PERIOD,
      C3_RST_ACT_LOW => C3_RST_ACT_LOW,
      C3_INPUT_CLK_TYPE => C3_INPUT_CLK_TYPE,
      C3_CALIB_SOFT_IP => C3_CALIB_SOFT_IP,
      C3_SIMULATION => C3_SIMULATION,
      DEBUG_EN => DEBUG_EN,
      C3_MEM_ADDR_ORDER => C3_MEM_ADDR_ORDER,
      C3_NUM_DQ_PINS => C3_NUM_DQ_PINS,
      C3_MEM_ADDR_WIDTH => C3_MEM_ADDR_WIDTH,
      C3_MEM_BANKADDR_WIDTH => C3_MEM_BANKADDR_WIDTH
    )
    port map
    (
        -- MCB connections
        mcb3_dram_dq     => mcb_xtr(15 downto 0),
        mcb3_dram_udqs   => mcb_xtr(16),
        mcb3_rzq         => mcb_xtr(18),
        mcb3_dram_a      => mcb_xtx(12 downto 0),
        mcb3_dram_ba     => mcb_xtx(14 downto 13),
        mcb3_dram_cke    => mcb_xtx(15),
        mcb3_dram_ras_n  => mcb_xtx(16),
        mcb3_dram_cas_n  => mcb_xtx(17),
        mcb3_dram_we_n   => mcb_xtx(18),
        mcb3_dram_dm     => mcb_xtx(19),
        mcb3_dram_udm    => mcb_xtx(20),
        mcb3_dram_dqs    => mcb_xtr(17),
        mcb3_dram_ck     => mcb_xcl(0),
        mcb3_dram_ck_n   => mcb_xcl(1),

        -- System Signals
        c3_sys_clk       => i_sys_clk,
        c3_sys_rst_n     => i_sys_rst_n,
        c3_calib_done    => s_calib_done,
        c3_clk0          => o_clk0,
        c3_rst0          => o_rst0,

        -- Port 0
        c3_p0_cmd_clk => c3_p0_cmd_clk,
        c3_p0_cmd_en => c3_p0_cmd_en,
        c3_p0_cmd_instr => c3_p0_cmd_instr,
        c3_p0_cmd_bl => c3_p0_cmd_bl,
        c3_p0_cmd_byte_addr => c3_p0_cmd_byte_addr,
        c3_p0_cmd_empty => c3_p0_cmd_empty,
        c3_p0_cmd_full => c3_p0_cmd_full,
        c3_p0_wr_clk => c3_p0_wr_clk,
        c3_p0_wr_en => c3_p0_wr_en,
        c3_p0_wr_mask => c3_p0_wr_mask,
        c3_p0_wr_data => c3_p0_wr_data,
        c3_p0_wr_full => c3_p0_wr_full,
        c3_p0_wr_empty => c3_p0_wr_empty,
        c3_p0_wr_count => c3_p0_wr_count,
        c3_p0_wr_underrun => c3_p0_wr_underrun,
        c3_p0_wr_error => c3_p0_wr_error,
        c3_p0_rd_clk => c3_p0_rd_clk,
        c3_p0_rd_en => c3_p0_rd_en,
        c3_p0_rd_data => c3_p0_rd_data,
        c3_p0_rd_full => c3_p0_rd_full,
        c3_p0_rd_empty => c3_p0_rd_empty,
        c3_p0_rd_count => c3_p0_rd_count,
        c3_p0_rd_overflow => c3_p0_rd_overflow,
        c3_p0_rd_error => c3_p0_rd_error,

        -- Port 1
        c3_p1_cmd_clk => c3_p1_cmd_clk,
        c3_p1_cmd_en => c3_p1_cmd_en,
        c3_p1_cmd_instr => c3_p1_cmd_instr,
        c3_p1_cmd_bl => c3_p1_cmd_bl,
        c3_p1_cmd_byte_addr => c3_p1_cmd_byte_addr,
        c3_p1_cmd_empty => c3_p1_cmd_empty,
        c3_p1_cmd_full => c3_p1_cmd_full,
        c3_p1_wr_clk => c3_p1_wr_clk,
        c3_p1_wr_en => c3_p1_wr_en,
        c3_p1_wr_mask => c3_p1_wr_mask,
        c3_p1_wr_data => c3_p1_wr_data,
        c3_p1_wr_full => c3_p1_wr_full,
        c3_p1_wr_empty => c3_p1_wr_empty,
        c3_p1_wr_count => c3_p1_wr_count,
        c3_p1_wr_underrun => c3_p1_wr_underrun,
        c3_p1_wr_error => c3_p1_wr_error,
        c3_p1_rd_clk => c3_p1_rd_clk,
        c3_p1_rd_en => c3_p1_rd_en,
        c3_p1_rd_data => c3_p1_rd_data,
        c3_p1_rd_full => c3_p1_rd_full,
        c3_p1_rd_empty => c3_p1_rd_empty,
        c3_p1_rd_count => c3_p1_rd_count,
        c3_p1_rd_overflow => c3_p1_rd_overflow,
        c3_p1_rd_error => c3_p1_rd_error
    );

    p0_fold : entity work.MigPort32Fold
    port map
    (
      mig_xtx => mig_xtx_p0,
      mig_xrx => mig_xrx_p0,
      mig_port_calib_done => s_calib_done,
      mig_port_cmd_clk => c3_p0_cmd_clk,
      mig_port_cmd_en => c3_p0_cmd_en,
      mig_port_cmd_instr => c3_p0_cmd_instr,
      mig_port_cmd_bl => c3_p0_cmd_bl,
      mig_port_cmd_byte_addr => c3_p0_cmd_byte_addr,
      mig_port_cmd_empty => c3_p0_cmd_empty,
      mig_port_cmd_full => c3_p0_cmd_full,
      mig_port_wr_clk => c3_p0_wr_clk,
      mig_port_wr_en => c3_p0_wr_en,
      mig_port_wr_mask => c3_p0_wr_mask,
      mig_port_wr_data => c3_p0_wr_data,
      mig_port_wr_full => c3_p0_wr_full,
      mig_port_wr_empty => c3_p0_wr_empty,
      mig_port_wr_count => c3_p0_wr_count,
      mig_port_wr_underrun => c3_p0_wr_underrun,
      mig_port_wr_error => c3_p0_wr_error,
      mig_port_rd_clk => c3_p0_rd_clk,
      mig_port_rd_en => c3_p0_rd_en,
      mig_port_rd_data => c3_p0_rd_data,
      mig_port_rd_full => c3_p0_rd_full,
      mig_port_rd_empty => c3_p0_rd_empty,
      mig_port_rd_count => c3_p0_rd_count,
      mig_port_rd_overflow => c3_p0_rd_overflow,
      mig_port_rd_error => c3_p0_rd_error
    );

    p1_fold : entity work.MigPort32Fold
    port map
    (
      mig_xtx => mig_xtx_p1,
      mig_xrx => mig_xrx_p1,
      mig_port_calib_done => s_calib_done,
      mig_port_cmd_clk => c3_p1_cmd_clk,
      mig_port_cmd_en => c3_p1_cmd_en,
      mig_port_cmd_instr => c3_p1_cmd_instr,
      mig_port_cmd_bl => c3_p1_cmd_bl,
      mig_port_cmd_byte_addr => c3_p1_cmd_byte_addr,
      mig_port_cmd_empty => c3_p1_cmd_empty,
      mig_port_cmd_full => c3_p1_cmd_full,
      mig_port_wr_clk => c3_p1_wr_clk,
      mig_port_wr_en => c3_p1_wr_en,
      mig_port_wr_mask => c3_p1_wr_mask,
      mig_port_wr_data => c3_p1_wr_data,
      mig_port_wr_full => c3_p1_wr_full,
      mig_port_wr_empty => c3_p1_wr_empty,
      mig_port_wr_count => c3_p1_wr_count,
      mig_port_wr_underrun => c3_p1_wr_underrun,
      mig_port_wr_error => c3_p1_wr_error,
      mig_port_rd_clk => c3_p1_rd_clk,
      mig_port_rd_en => c3_p1_rd_en,
      mig_port_rd_data => c3_p1_rd_data,
      mig_port_rd_full => c3_p1_rd_full,
      mig_port_rd_empty => c3_p1_rd_empty,
      mig_port_rd_count => c3_p1_rd_count,
      mig_port_rd_overflow => c3_p1_rd_overflow,
      mig_port_rd_error => c3_p1_rd_error
    );

end Behavioral;
