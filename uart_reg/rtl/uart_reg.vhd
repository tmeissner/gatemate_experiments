-- This design implements a register file which can
-- be accessed by an UART with 9600 baud
--
-- See into uart_ctrl.vhd for documentation of the protocol
-- used to read / write the register file.


library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library gatemate;
use gatemate.components.all;


entity uart_reg is
port (
  clk_i     : in  std_logic;  -- 10 MHz clock
  rst_n_i   : in  std_logic;  -- SW3 button
  uart_rx_i : in  std_logic;  -- PMODA IO3
  uart_tx_o : out std_logic   -- PMODA IO5
);
end entity uart_reg;


architecture rtl of uart_reg is

  signal s_pll_clk  : std_logic;
  signal s_pll_lock : std_logic;

  signal s_rst_n    : std_logic;
  signal s_usr_rstn : std_logic;

  signal s_uart_rx_tdata  : std_logic_vector(7 downto 0);
  signal s_uart_rx_tvalid : std_logic;
  signal s_uart_rx_tready : std_logic;

  signal s_uart_tx_tdata  : std_logic_vector(7 downto 0);
  signal s_uart_tx_tvalid : std_logic;
  signal s_uart_tx_tready : std_logic;

begin

  pll : CC_PLL
  generic map (
    REF_CLK => "10",
    OUT_CLK => "10",
    PERF_MD => "SPEED"
  )
  port map (
    CLK_REF             => clk_i,
    CLK_FEEDBACK        => '0',
    USR_CLK_REF         => '0',
    USR_LOCKED_STDY_RST => '0',
    USR_PLL_LOCKED_STDY => open,
    USR_PLL_LOCKED      => s_pll_lock,
    CLK270              => open,
    CLK180              => open,
    CLK0                => s_pll_clk,
    CLK90               => open,
    CLK_REF_OUT         => open
  );

  cc_usr_rstn_inst : CC_USR_RSTN
  port map (
    USR_RSTN => s_usr_rstn
  );

  uart_rx : entity work.uart_rx
  generic map (
    CLK_DIV => 1040
  )
  port map (
    -- globals
    rst_n_i  => s_rst_n,
    clk_i    => s_pll_clk,
    -- axis user interface
    tdata_o  => s_uart_rx_tdata,
    tvalid_o => s_uart_rx_tvalid,
    tready_i => s_uart_rx_tready,
    -- uart interface
    rx_i     => uart_rx_i
  );

  uart_ctrl : entity work.uart_ctrl
  port map (
    -- globals
    rst_n_i  => s_rst_n,
    clk_i    => s_pll_clk,
    -- uart rx interface
    tdata_i  => s_uart_rx_tdata,
    tvalid_i => s_uart_rx_tvalid,
    tready_o => s_uart_rx_tready,
    -- uart tx interface
    tdata_o  => s_uart_tx_tdata,
    tvalid_o => s_uart_tx_tvalid,
    tready_i => s_uart_tx_tready
  );

  uart_tx : entity work.uart_tx
  generic map (
    CLK_DIV => 1040
  )
  port map (
    -- globals
    rst_n_i  => s_rst_n,
    clk_i    => s_pll_clk,
    -- axis user interface
    tdata_i  => s_uart_tx_tdata,
    tvalid_i => s_uart_tx_tvalid,
    tready_o => s_uart_tx_tready,
    -- uart interface
    tx_o     => uart_tx_o
  );

  s_rst_n <= rst_n_i and s_pll_lock and s_usr_rstn;

end architecture;
