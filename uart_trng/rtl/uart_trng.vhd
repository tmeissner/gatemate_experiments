-- This design implements a register file which can
-- be accessed by an UART with 9600 baud
--
-- See into uart_ctrl.vhd for documentation of the protocol
-- used to read / write the register file.


library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library gatemate;
use gatemate.components.all;


entity uart_trng is
generic (
  SIM : natural := 0
);
port (
  clk_i     : in  std_logic;  -- 10 MHz clock
  rst_n_i   : in  std_logic;  -- SW3 button
  uart_tx_o : out std_logic   -- PMODA IO5
);
end entity uart_trng;


architecture rtl of uart_trng is

  signal s_pll_clk  : std_logic;
  signal s_pll_lock : std_logic;

  signal s_rst_n    : std_logic;
  signal s_usr_rstn : std_logic;

  signal s_uart_tx_tdata  : std_logic_vector(7 downto 0);
  signal s_uart_tx_tvalid : std_logic;
  signal s_uart_tx_tready : std_logic;

  signal s_firo_run  : std_logic;
  signal s_firo_data : std_logic;

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

  firo_ctrl : entity work.firo_ctrl 
  generic map (
    EXTRACT => true
  )
  port map (
    -- system
    rst_n_i  => s_rst_n,
    clk_i    => s_pll_clk,
    -- axis in
    tvalid_i => '1',
    tready_o => open,
    -- axis out
    tdata_o  => s_uart_tx_tdata,
    tvalid_o => s_uart_tx_tvalid,
    tready_i => s_uart_tx_tready,
    -- firo
    frun_o   => s_firo_run,
    fdata_i  => s_firo_data
  );

  SIMULATION : if (SIM /= 0) generate
    -- simple random bit generator
    RandomGenP : process (s_pll_clk, s_firo_run) is
      variable v_seed1, v_seed2 : positive := 1;
      variable v_real_rand      : real;
    begin
      if (not s_firo_run) then
        s_firo_data <= '0';
      elsif (s_pll_clk'event) then
        uniform(v_seed1, v_seed2, v_real_rand);
        if (v_real_rand < 0.5) then
          s_firo_data <= '0';
        else
          s_firo_data <= '1';
        end if;
      end if;
    end process RandomGenP;
  else generate
    firo : entity work.firo
    generic map (
      TOGGLE => true
    )
    port map (
      frun_i  => s_firo_run,
      fdata_o => s_firo_data
    );
  end generate;

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
