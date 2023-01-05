library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.env.all;


entity tb_neorv32_aes is
end entity tb_neorv32_aes;


architecture sim of tb_neorv32_aes is

  constant c_baudrate  : natural := 9600;
  constant c_period_ns : time := 1000000000 / c_baudrate * ns;

  procedure uart_send (       data : in std_logic_vector(7 downto 0);
                       signal   tx : out std_logic) is
  begin
    report "UART send: 0x" & to_hstring(data);
    tx <= '0';
    wait for c_period_ns;
    for i in 0 to 7 loop
      tx <= data(i);
      wait for c_period_ns;
    end loop;
    tx <= '1';
    wait for c_period_ns;
  end procedure;

  procedure uart_recv (       data : out std_logic_vector(7 downto 0);
                       signal   rx : in  std_logic) is
  begin
    wait until not rx;
    wait for c_period_ns;   -- Skip start bit
    wait for c_period_ns/2;
    for i in 0 to 7 loop
      data(i) := rx;
      wait for c_period_ns;
    end loop;
    report "UART recv: 0x" & to_hstring(data);
  end procedure;

  signal s_clk   : std_logic := '1';
  signal s_rst_n : std_logic := '0';

  signal s_len_n : std_logic_vector(7 downto 0);
  signal s_debug : std_logic_vector(15 downto 0);

begin

  dut : entity work.neorv32_aes
  port map (
    clk_i     => s_clk,
    rst_n_i   => s_rst_n,
    --
    led_n_o => s_len_n,
    --uart_tx_o => s_uart_tx
    --uart_rx_i => s_uart_rx
    debug_o => s_debug
  );

  s_rst_n <= '1' after 120 ns;
  s_clk   <= not s_clk after 50 ns;

  process is
  begin
    wait for 2 ms;
    stop(0);
  end process;


end architecture;
