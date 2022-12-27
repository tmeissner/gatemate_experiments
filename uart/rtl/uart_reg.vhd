-- This design should display incrementing binary numbers
-- at LED1-LED8 of the GateMate FPGA Starter Kit.


library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library gatemate;
use gatemate.components.all;


entity uart_reg is
port (
  clk_i     : in  std_logic;                    -- 10 MHz clock
  rst_n_i   : in  std_logic;                    -- SW3 button
  uart_rx_i : in  std_logic;
  uart_tx_o : out std_logic;
  led_n_o   : out std_logic_vector(2 downto 0)  -- LED1..LED2
);
end entity uart_reg;


architecture rtl of uart_reg is

  signal s_pll_clk  : std_logic;
  signal s_pll_lock : std_logic;
  signal s_clk_en   : boolean;

  signal s_rst_n   : std_logic;
  signal s_cfg_end : std_logic;

begin

  pll : CC_PLL
  generic map (
    REF_CLK => "10",
    OUT_CLK => "1",
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

  s_rst_n <= rst_n_i and s_pll_lock and s_cfg_end;

  -- Start with simple loop
  uart_tx_o <= uart_rx_i;

  -- Debug output
  led_n_o <= s_rst_n & not (s_pll_lock, s_cfg_end);

end architecture;
