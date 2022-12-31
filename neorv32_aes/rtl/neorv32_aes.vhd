-- #################################################################################################
-- # << NEORV32 - Example setup including the bootloader, for the Gatemate (c) Eval Board >>       #
-- # ********************************************************************************************* #
-- # BSD 3-Clause License                                                                          #
-- #                                                                                               #
-- # Copyright (c) 2022, Torsten Meissner. All rights reserved.                                    #
-- #                                                                                               #
-- # Redistribution and use in source and binary forms, with or without modification, are          #
-- # permitted provided that the following conditions are met:                                     #
-- #                                                                                               #
-- # 1. Redistributions of source code must retain the above copyright notice, this list of        #
-- #    conditions and the following disclaimer.                                                   #
-- #                                                                                               #
-- # 2. Redistributions in binary form must reproduce the above copyright notice, this list of     #
-- #    conditions and the following disclaimer in the documentation and/or other materials        #
-- #    provided with the distribution.                                                            #
-- #                                                                                               #
-- # 3. Neither the name of the copyright holder nor the names of its contributors may be used to  #
-- #    endorse or promote products derived from this software without specific prior written      #
-- #    permission.                                                                                #
-- #                                                                                               #
-- # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS   #
-- # OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF               #
-- # MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE    #
-- # COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,     #
-- # EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE #
-- # GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED    #
-- # AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING     #
-- # NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED  #
-- # OF THE POSSIBILITY OF SUCH DAMAGE.                                                            #
-- # ********************************************************************************************* #
-- # The NEORV32 Processor - https://github.com/stnolting/neorv32              (c) Stephan Nolting #
-- #################################################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library gatemate;
use gatemate.components.all;


entity neorv32_aes is
  port (
    -- Clock and Reset inputs
    clk_i     : in  std_logic;  -- 10 MHz clock
    rst_n_i   : in  std_logic;  -- SW3 button
    -- LED outputs
    led_n_o   : out std_logic_vector(7 downto 0);
    -- UART0
    uart_rx_i : in  std_logic;  -- PMODA IO
    uart_tx_o : out std_logic   -- PMODA IO
  );
end entity;

architecture rtl of neorv32_aes is

  -- configuration --
  constant f_clock_c : natural := 26_000_000; -- clock frequency in Hz

  -- Globals
  signal s_pll_lock : std_logic;
  signal s_pll_clk  : std_logic;
  signal s_cfg_end  : std_logic;

  signal s_rst_n : std_logic;

  signal s_con_pwm : std_logic_vector(2 downto 0);
  
begin

  PLL : CC_PLL
  generic map (
    REF_CLK => "10",
    OUT_CLK => "26",
    PERF_MD => "SPEED"
  )
  port map (
    CLK_REF             => clk_i,
    USR_CLK_REF         => '0',
    CLK_FEEDBACK        => '0',
    USR_LOCKED_STDY_RST => '0',
    USR_PLL_LOCKED_STDY => open,
    USR_PLL_LOCKED      => s_pll_lock,
    CLK0                => s_pll_clk,
    CLK90               => open,
    CLK180              => open,
    CLK270              => open,
    CLK_REF_OUT         => open
  );

  cfg_end : CC_CFG_END
  port map (
    CFG_END => s_cfg_end
  );

  s_rst_n <= s_pll_lock and s_cfg_end and rst_n_i;

  -- The core of the problem ----------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  neorv32_inst: entity work.neorv32_ProcessorTop_Minimal
  generic map (
    CLOCK_FREQUENCY => f_clock_c -- clock frequency of s_pll_clk in Hz
  )
  port map (
    -- Global control --
    clk_i  => std_ulogic(s_pll_clk),
    rstn_i => std_ulogic(s_rst_n),
	    -- PWM (to on-board RGB LED) --
    pwm_o  => s_con_pwm
  );

  -- IO Connection --------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  led_n_o(4 downto 0) <= (others => '1');
  led_n_o(7 downto 5) <= s_con_pwm;
  uart_tx_o <= uart_rx_i;

end architecture;
