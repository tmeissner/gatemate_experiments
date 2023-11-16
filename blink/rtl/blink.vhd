-- This design should display incrementing binary numbers
-- at LED1-LED8 of the GateMate FPGA Starter Kit.


library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library gatemate;
use gatemate.components.all;


entity blink is
generic (
  SIM : natural := 0
);
port (
  clk_i   : in  std_logic;                    -- 10 MHz clock
  rst_n_i : in  std_logic;                    -- SW3 button
  led_n_o : out std_logic_vector(7 downto 0)  -- LED1..LED8
);
end entity blink;


architecture rtl of blink is

  subtype t_clk_cnt is unsigned(19 downto 0);
  signal s_clk_cnt     : t_clk_cnt;
  signal s_clk_cnt_end : t_clk_cnt;

  signal s_pll_clk  : std_logic;
  signal s_pll_lock : std_logic;
  signal s_clk_en   : boolean;

  signal s_rst_n    : std_logic;
  signal s_usr_rstn : std_logic;

  signal s_sys_rst_n : std_logic;

begin

  pll : CC_PLL
  generic map (
    REF_CLK => "10",
    OUT_CLK => "2",
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

  -- This works
  s_rst_n <= rst_n_i and s_pll_lock and s_usr_rstn;

  -- This doesn't work.
  -- The reset module seems to be removed during Yosys flatten pass, even
  -- when the output is connected with an output port, WHY does this happen?
  --   2.5. Executing FLATTEN pass (flatten design).
  --   Deleting now unused module reset_sync_c4ea21bb365bbeeaf5f2c654883e56d11e43c44e.
  --   <suppressed ~1 debug messages>
  reset : entity work.reset_sync
  generic map (
    POLARITY => '0'
  )
  port map (
    clk_i => s_pll_clk,
    rst_i => rst_n_i and s_pll_lock and s_usr_rstn,
    rst_o => s_sys_rst_n
  );

  s_clk_cnt_end <= 20x"FFFFF" when SIM = 0 else  -- synthesis
                   20x"000FF";                   -- simulation

  process (s_pll_clk, s_rst_n) is
  begin
    if (not s_rst_n) then
      s_clk_cnt <= (others => '0');
    elsif (rising_edge(s_pll_clk)) then
      if (s_clk_cnt = s_clk_cnt_end) then
        s_clk_cnt <= (others => '0');
      else
        s_clk_cnt <= s_clk_cnt + 1;
      end if;
    end if;
  end process;

  s_clk_en <= s_clk_cnt = s_clk_cnt_end;

  process (s_pll_clk, s_rst_n) is
  begin
    if (not s_rst_n) then
      led_n_o <= x"FE";
    elsif (rising_edge(s_pll_clk)) then
      if (s_clk_en) then
        led_n_o <= led_n_o(6 downto 0) & led_n_o(7);
      end if;
    end if;
  end process;


end architecture;
