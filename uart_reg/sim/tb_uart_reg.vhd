library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.env.all;


entity tb_uart_reg is
end entity tb_uart_reg;


architecture sim of tb_uart_reg is

  signal s_clk   : std_logic := '1';
  signal s_rst_n : std_logic := '0';

  signal s_uart_rx : std_logic := '1';
  signal s_uart_tx : std_logic;

  constant c_baudrate  : natural := 9600;
  constant c_period_ns : time := 1000000000 / c_baudrate * ns;

begin

  dut : entity work.uart_reg
  port map (
    clk_i     => s_clk,
    rst_n_i   => s_rst_n,
    uart_rx_i => s_uart_rx,
    uart_tx_o => s_uart_tx
  );

  s_rst_n <= '1' after 120 ns;
  s_clk   <= not s_clk after 50 ns;

  SendP : process is
    variable v_data : std_logic_vector(7 downto 0);
  begin
    wait until s_rst_n;
    wait until rising_edge(s_clk);
    wait for 200 us;
    for tx in 0 to 255 loop
      v_data := std_logic_vector(to_unsigned(tx, 8));
      report "UART send: 0x" & to_hstring(v_data);
      s_uart_rx <= '0';
      wait for c_period_ns;
      for i in 0 to 7 loop
        s_uart_rx <= v_data(i);
        wait for c_period_ns;
      end loop;
      s_uart_rx <= '1';
      wait for c_period_ns;
    end loop;
    wait;
  end process;

  ReceiveP : process is
    variable v_data : std_logic_vector(7 downto 0);
  begin
    wait until s_rst_n;
    wait until rising_edge(s_clk);
    for rx in 0 to 255 loop
      wait until not s_uart_tx;
      wait for c_period_ns;   -- Skip start bit
      wait for c_period_ns/2;
      for i in 0 to 7 loop
        v_data(i) := s_uart_tx;
        wait for c_period_ns;
      end loop;
      report "UART recv: 0x" & to_hstring(v_data);
      assert v_data = std_logic_vector(to_unsigned(rx, 8))
        report "UART receive error, got 0x" & to_hstring(v_data) & ", expected 0x" & to_hstring(v_data)
        severity failure;
    end loop;
    wait for 200 us;
    report "Simulation finished :-)";
    stop(0);
  end process;

end architecture;
