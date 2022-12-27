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
  CLK270              : out std_logic;
  CLK180              : out std_logic;
  CLK0                : out std_logic := '1';
  CLK90               : out std_logic := '0';
  CLK_REF_OUT         : out std_logic
);
end entity;


architecture sim of CC_PLL is

  constant c_period_ns : real := (1000.0 / real'value(OUT_CLK));
  constant c_half_period_ns : real := c_period_ns / 2.0;

begin

  Log : process is
  begin
    report CC_PLL'instance_name & " CC_PLL CLK0 = " & to_string(1000.0/(c_period_ns), 2) & " MHz";
    wait;
  end process;
  
  CLK0   <= not CLK0 after c_half_period_ns * ns;
  CLK90  <= transport CLK0 after (c_half_period_ns / 2.0) * ns;
  CLK180 <= not CLK0;
  CLK270 <= not CLK90;

  CLK_REF_OUT <= CLK_REF;

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
