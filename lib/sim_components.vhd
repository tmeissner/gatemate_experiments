library ieee ;
use ieee.std_logic_1164.all;
use ieee.math_real.all;


entity CC_PLL is
generic (
  REF_CLK         : string := "0";          -- reference clk in MHz
  OUT_CLK         : string := "0";          -- output clk in MHz
  PERF_MD         : string := "UNDEFINED";  -- LOWPOWER, ECONOMY, SPEED (optional, global, setting of Place&Route can be used instead)
  LOW_JITTER      : natural := 1;           -- 0: disable, 1: enable low jitter mode
  CI_FILTER_CONST : natural := 2;           -- optional CI filter constant
  CP_FILTER_CONST : natural := 4            -- optional CP filter constant
);
port (
  CLK_REF             : in std_logic;
  CLK_FEEDBACK        : in std_logic;
  USR_CLK_REF         : in std_logic;
  USR_LOCKED_STDY_RST : in std_logic;
  USR_PLL_LOCKED_STDY : out std_logic;
  USR_PLL_LOCKED      : out std_logic;
  CLK270              : out std_logic := '0';
  CLK180              : out std_logic := '0';
  CLK0                : out std_logic := '0';
  CLK90               : out std_logic := '0';
  CLK_REF_OUT         : out std_logic
);
end entity;


architecture sim of CC_PLL is

  signal s_pll_clk_2   : std_logic := '1';
  signal s_pll_clk_pos : std_logic := '0';
  signal s_pll_clk_neg : std_logic := '0';

begin

  -- First create a clock with freq = 2 * OUT_CLK;
  s_pll_clk_2 <= not s_pll_clk_2 after (250.0 / real'value(OUT_CLK)) * ns;

  -- Then create clocks with freq = OUT_CLK and shifted by 180 degree
  s_pll_clk_pos <= not s_pll_clk_pos when rising_edge(s_pll_clk_2);
  s_pll_clk_neg <= not s_pll_clk_pos when falling_edge(s_pll_clk_2);

  -- Finally assign the clock outputs to avoid delta cycle delay problems
  -- All these clocks should by phase aligned
  CLK0   <= s_pll_clk_pos;
  CLK90  <= s_pll_clk_neg;
  CLK180 <= not s_pll_clk_pos;
  CLK270 <= not s_pll_clk_neg;

  CLK_REF_OUT <= CLK_REF or USR_CLK_REF;

  USR_PLL_LOCKED <= '1';

end architecture;


library ieee ;
use ieee.std_logic_1164.all;


entity CC_CFG_END is
port (
  CFG_END : out std_logic
);
end entity;


architecture sim of CC_CFG_END is
begin

  CFG_END <= '1';

end architecture;
