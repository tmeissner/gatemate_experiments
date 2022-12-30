-- Simple UART loop with UART RX & TX units and FIFO buffer
-- between. It's working at baudrate 9600.


library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library gatemate;
use gatemate.components.all;


entity uart_loop is
port (
  clk_i     : in  std_logic;  -- 10 MHz clock
  rst_n_i   : in  std_logic;  -- SW3 button
  uart_rx_i : in  std_logic;  -- PMODA IO3
  uart_tx_o : out std_logic   -- PMODA IO5
);
end entity uart_loop;


architecture rtl of uart_loop is

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

begin

  pll : CC_PLL
  generic map (
    REF_CLK => "10",
    OUT_CLK => "10",
    PERF_MD => "ECONOMY"
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

  axis_fifo : entity work.axis_fifo
  generic map (
    DEPTH => 16,
    WIDTH => 8
  )
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

-- s_uart_tx_tdata  <= s_uart_rx_tdata;
-- s_uart_tx_tvalid <= s_uart_rx_tvalid;
-- s_uart_rx_tready <= s_uart_tx_tready;

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

end architecture;
