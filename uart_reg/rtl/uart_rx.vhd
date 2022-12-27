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


entity uart_rx is
  generic (
    CLK_DIV : natural := 10
  );
  port (
    -- globals
    rst_n_i  : in  std_logic;
    clk_i    : in  std_logic;
    -- axis user interface
    tdata_o  : out std_logic_vector(7 downto 0);
    tvalid_o : out std_logic;
    tready_i : in  std_logic;
    -- uart interface
    rx_i     : in  std_logic
  );
end entity uart_rx;


architecture rtl of uart_rx is

  type t_uart_state is (IDLE, RECEIVE, VALID);
  signal s_uart_state : t_uart_state;

  signal s_clk_en : std_logic;
  signal s_clk_cnt : natural range 0 to CLK_DIV-1;
  signal s_bit_cnt : natural range 0 to tdata_o'length+1;
  signal s_rx_d : std_logic_vector(3 downto 0);

begin

  ClkDivP : process (clk_i, rst_n_i) is
  begin
    if (not rst_n_i) then
      s_clk_cnt <= CLK_DIV-1;
    elsif (rising_edge(clk_i)) then
      if (s_uart_state = IDLE) then
        s_clk_cnt <= CLK_DIV-2;
      elsif (s_uart_state = RECEIVE) then
        if (s_clk_cnt = 0) then
          s_clk_cnt <= CLK_DIV-1;
        else
          s_clk_cnt <= s_clk_cnt - 1;
        end if;
      end if;
    end if;
  end process ClkDivP;

  s_clk_en <= '1' when s_uart_state = RECEIVE and s_clk_cnt = CLK_DIV/2-1 else '0';

  RxP : process (clk_i, rst_n_i) is
  begin
    if (not rst_n_i) then
      s_uart_state <= IDLE;
      tdata_o      <= (others => '0');
      s_rx_d       <= x"1";
      s_bit_cnt    <= 0;
    elsif (rising_edge(clk_i)) then
      s_rx_d <= s_rx_d(2 downto 0) & rx_i;
      FsmL : case s_uart_state is
        when IDLE =>
          s_bit_cnt <= tdata_o'length+1;
          if (s_rx_d = "1000") then
            s_uart_state <= RECEIVE;
          end if;
        when RECEIVE =>
          if (s_clk_en) then
            if (s_bit_cnt = 0) then
              s_uart_state <= VALID;
            else
              tdata_o  <= s_rx_d(3) & tdata_o(tdata_o'length-1 downto 1);
              s_bit_cnt <= s_bit_cnt - 1;
            end if;
          end if;
        when VALID =>
          if (tready_i) then
            s_uart_state <= IDLE;
          end if;
      end case;
    end if;
  end process RxP;

  tvalid_o <= '1' when s_uart_state = VALID else '0';

end architecture rtl;
