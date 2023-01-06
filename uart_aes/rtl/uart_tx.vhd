--  Copyright (c) 2022 by Torsten Meissner
--
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--
--      https://www.apache.org/licenses/LICENSE-2.0
--
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.



library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity uart_tx is
  generic (
    CLK_DIV : natural := 10
  );
  port (
    -- globals
    rst_n_i  : in  std_logic;
    clk_i    : in  std_logic;
    -- axis user interface
    tdata_i  : in  std_logic_vector(7 downto 0);
    tvalid_i : in  std_logic;
    tready_o : out std_logic;
    -- uart interface
    tx_o     : out std_logic
  );
end entity uart_tx;


architecture rtl of uart_tx is

  type t_uart_state is (IDLE, SEND);
  signal s_uart_state : t_uart_state;

  signal s_data   : std_logic_vector(tdata_i'length+1 downto 0);
  signal s_clk_cnt : natural range 0 to CLK_DIV-1;
  signal s_clk_en : std_logic;
  signal s_bit_cnt : natural range 0 to s_data'length-1;

begin

  ClkDivP : process (clk_i, rst_n_i) is
  begin
    if (not rst_n_i) then
      s_clk_cnt <= CLK_DIV-1;
    elsif (rising_edge(clk_i)) then
      if (s_uart_state = IDLE) then
        s_clk_cnt <= CLK_DIV-2;
      elsif (s_uart_state = SEND) then
        if (s_clk_cnt = 0) then
          s_clk_cnt <= CLK_DIV-1;
        else
          s_clk_cnt <= s_clk_cnt - 1;
        end if;
      end if;
    end if;
  end process ClkDivP;

  s_clk_en <= '1' when s_uart_state = SEND and s_clk_cnt = 0 else '0';

  TxP : process (clk_i, rst_n_i) is
  begin
    if (not rst_n_i) then
      s_uart_state <= IDLE;
      s_data       <= (0 => '1', others => '0');
      s_bit_cnt    <= 0;
    elsif (rising_edge(clk_i)) then
      FsmL : case s_uart_state is
        when IDLE =>
          s_bit_cnt <= s_data'length-1;
          if (tvalid_i) then
            s_data <= '1' & tdata_i & '0';
            s_uart_state <= SEND;
          end if;
        when SEND =>
          if (s_clk_en) then
            s_data <= '1' & s_data(s_data'length-1 downto 1);
            if (s_bit_cnt = 0) then
              s_uart_state <= IDLE;
            else
              s_bit_cnt <= s_bit_cnt - 1;
            end if;
          end if;
      end case;
    end if;
  end process TxP;

  tready_o <= '1' when s_uart_state = IDLE else '0';

  tx_o <= s_data(0);

end architecture rtl;
