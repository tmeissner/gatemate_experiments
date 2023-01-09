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

library neorv32;
use neorv32.neorv32_package.all;

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
--    uart_rx_i : in  std_logic;  -- PMODA IO
--    uart_tx_o : out std_logic   -- PMODA IO
    debug_o : out std_logic_vector(15 downto 0)
  );
end entity;

architecture rtl of neorv32_aes is

  -- configuration --
  constant f_clock_c : natural := 10_000_000; -- clock frequency in Hz

  -- Globals
  signal s_pll_lock : std_logic;
  signal s_pll_clk  : std_logic;
  signal s_cfg_end  : std_logic;

  signal s_rst_n          : std_logic;
  signal s_rst_debounced : std_logic;

  signal s_con_gpio : std_ulogic_vector(63 downto 0);

  signal s_debug : std_logic_vector(63 downto 0);
  
begin

  PLL : CC_PLL
  generic map (
    REF_CLK => "10",
    OUT_CLK => "10",
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

   rst_debounce : block is
    signal s_rst_d : std_logic_vector(29 downto 0);
  begin
    process (s_pll_clk, rst_n_i) is
    begin
      if (not rst_n_i) then
        s_rst_d <= (others => '0');
      elsif (rising_edge(s_pll_clk)) then
        s_rst_d <= s_rst_d(s_rst_d'left-1 downto 0) & rst_n_i;
      end if;
    end process;
    s_rst_debounced <= and s_rst_d;
  end block rst_debounce;

  s_rst_n <= s_pll_lock and s_cfg_end and s_rst_debounced;

  -- The core of the problem ----------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  neorv32_inst: entity neorv32.neorv32_top
  generic map (
    CLOCK_FREQUENCY              => f_clock_c, -- clock frequency of s_pll_clk in Hz
    INT_BOOTLOADER_EN            => false,     -- boot configuration: true = boot explicit bootloader; false = boot from int/ext (I)MEM
    -- RISC-V CPU Extensions --
    CPU_EXTENSION_RISCV_C        => false,     -- implement compressed extension?
    CPU_EXTENSION_RISCV_M        => true,      -- implement mul/div extension?
    CPU_EXTENSION_RISCV_Zicsr    => true,      -- implement CSR system?
    CPU_EXTENSION_RISCV_Zicntr   => true,      -- implement base counters?
    -- Tuning Options --
    FAST_MUL_EN                  => false,
    FAST_SHIFT_EN                => false,
    -- Internal Instruction memory --
    MEM_INT_IMEM_EN              => true,      -- implement processor-internal instruction memory
    MEM_INT_IMEM_SIZE            => 4*1024,    --16*1024,   -- size of processor-internal instruction memory in bytes
    -- Internal Data memory --
    MEM_INT_DMEM_EN              => true,       -- implement processor-internal data memory
    MEM_INT_DMEM_SIZE            => 8*1024,    -- size of processor-internal data memory in bytes
    -- Processor peripherals --
    IO_GPIO_EN                   => true,      -- implement general purpose input/output port unit (GPIO)?
    IO_MTIME_EN                  => true,      -- implement machine system timer (MTIME)?
    IO_UART0_EN                  => false,     -- implement primary universal asynchronous receiver/transmitter (UART0)?
    IO_CFS_EN                    => false,     -- implement custom functions subsystem (CFS)?
    IO_AES_EN                    => true       -- implement AES(128) custom function?
  )
  port map (
    -- Global control --
    clk_i  => std_ulogic(s_pll_clk),
    rstn_i => std_ulogic(s_rst_n),
	  -- GPIO
    gpio_o  => s_con_gpio,
    -- primary UART0
    uart0_txd_o => open,  -- uart_tx_o,
    uart0_rxd_i => '1',  -- uart_rx_i,
    -- debug
    debug_o => s_debug
  );

  debug_o <= s_debug(15 downto 0);

  -- p_r ERROR when connecting uart_rx_i & yosys option -retime (with both Yosys inferred & instantiated CC_BRAM_40K or CC_BRAM_40K memory)
  --   FATAL ERROR: RAM 4070 Output DOA[6] not used but Input DIA[6] used!
  --   program finished with exit code: 2

  -- IO Connection --------------------------------------------------------------------------
  led_n_o <= not std_logic_vector(s_con_gpio(7 downto 0));

end architecture;
