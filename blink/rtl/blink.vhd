-- This design should display incrementing binary numbers
-- at LED1-LED8 of the GateMate FPGA Starter Kit.


library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library gatemate;
use gatemate.components.all;


entity blink is
port (
  clk_i   : in  std_logic;                    -- 10 MHz clock
  rst_n_i : in  std_logic;                    -- SW3 button
  led_n_o : out std_logic_vector(7 downto 0)  -- LED1..LED8
);
end entity blink;


architecture rtl of blink is

  signal s_pll_clk  : std_logic;
  signal s_pll_lock : std_logic;
  signal s_clk_cnt  : unsigned(19 downto 0);
  signal s_clk_en   : boolean;

  signal s_rst_n   : std_logic;
  signal s_cfg_end : std_logic;

  signal s_led : unsigned(led_n_o'range);

begin

  pll : CC_PLL
  generic map (
    REF_CLK => "10",
    OUT_CLK => "2",
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

  process (s_pll_clk, s_rst_n) is
  begin
    if (not s_rst_n) then
      s_clk_cnt <= (others => '0');
    elsif (rising_edge(s_pll_clk)) then
      s_clk_cnt <= s_clk_cnt + 1;
    end if;
  end process;

  s_clk_en <= s_clk_cnt = (s_clk_cnt'range => '1');

  process (s_pll_clk, s_rst_n) is
  begin
    if (not s_rst_n) then
      s_led <= x"01";
    elsif (rising_edge(s_pll_clk)) then
      if (s_clk_en) then
        s_led <= s_led(6 downto 0) & s_led(7);
      end if;
    end if;
  end process;

  led_n_o <= not std_logic_vector(s_led);

end architecture;
