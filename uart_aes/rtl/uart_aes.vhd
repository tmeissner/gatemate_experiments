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

library cryptocores;

use work.uart_aes_types.all;


entity uart_aes is
port (
  clk_i     : in  std_logic;  -- 10 MHz clock
  rst_n_i   : in  std_logic;  -- SW3 button
  uart_rx_i : in  std_logic;  -- PMODA IO3
  uart_tx_o : out std_logic;  -- PMODA IO5
  led_n_o   : out std_logic_vector(3 downto 0)
);
end entity uart_aes;


architecture rtl of uart_aes is

  signal s_pll_clk  : std_logic;
  signal s_pll_lock : std_logic;

  signal s_rst_n   : std_logic;
  signal s_cfg_end : std_logic;

  signal s_uart_rx_tdata  : std_logic_vector(7 downto 0);
  signal s_uart_rx_tvalid : std_logic;
  signal s_uart_rx_tready : std_logic;

  signal s_uart_tx_tdata  : std_logic_vector(7 downto 0);
  signal s_uart_tx_tvalid : std_logic;
  signal s_uart_tx_tready : std_logic;

  signal s_ctrl_aes_m2s : t_axis_ctrl_aes_m2s;
  signal s_ctrl_aes_s2m : t_axis_s2m;
  signal s_aes_ctrl_m2s : t_axis_aes_ctrl_m2s;
  signal s_aes_ctrl_s2m : t_axis_s2m;

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

  cfg_end_inst : CC_CFG_END
  port map (
    CFG_END => s_cfg_end
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
    tready_i => s_uart_tx_tready,
    -- aes out
    ctrl_aes_o => s_ctrl_aes_m2s,
    ctrl_aes_i => s_ctrl_aes_s2m,
    -- aes in
    aes_ctrl_i => s_aes_ctrl_m2s,
    aes_ctrl_o => s_aes_ctrl_s2m
  );

  aes_inst : entity cryptocores.ctraes
  port map (
    reset_i  => s_rst_n,
    clk_i    => s_pll_clk,
    start_i  => s_ctrl_aes_m2s.tuser.start,
    nonce_i  => s_ctrl_aes_m2s.tuser.nonce,
    key_i    => s_ctrl_aes_m2s.tuser.key,
    data_i   => s_ctrl_aes_m2s.tdata,
    valid_i  => s_ctrl_aes_m2s.tvalid,
    accept_o => s_ctrl_aes_s2m.tready,
    data_o   => s_aes_ctrl_m2s.tdata,
    valid_o  => s_aes_ctrl_m2s.tvalid,
    accept_i => s_aes_ctrl_s2m.tready
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

  s_rst_n <= rst_n_i and s_pll_lock and s_cfg_end;

  -- Lets some LEDs blink
  led_n_o(0) <= rst_n_i;                                -- reset button
  led_n_o(1) <= s_uart_rx_tready and s_uart_tx_tvalid;  -- uart ctrl ready
  led_n_o(2) <= not s_uart_rx_tready;                   -- uart received
  led_n_o(3) <= not s_uart_tx_tvalid;                   -- uart send

end architecture;
