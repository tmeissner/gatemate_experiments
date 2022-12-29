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
    -- First read all registers
    for i in 0 to 7 loop
      v_data := std_logic_vector(to_unsigned(i, 4)) & x"0";
      uart_send(v_data, s_uart_rx);
    end loop;
    -- Then write all registers
    for i in 0 to 7 loop
      v_data := std_logic_vector(to_unsigned(i, 4)) & x"1";
      uart_send(v_data, s_uart_rx);
      uart_send(x"FF", s_uart_rx);
    end loop;
    -- Finally read all registers again after write
    for i in 0 to 7 loop
      v_data := std_logic_vector(to_unsigned(i, 4)) & x"0";
      uart_send(v_data, s_uart_rx);
    end loop;
    wait;
  end process;

  ReceiveP : process is
    type t_exp is array (0 to 7) of std_logic_vector(7 downto 0);
    variable v_exp  : t_exp;
    variable v_data : std_logic_vector(7 downto 0);
  begin
    wait until s_rst_n;
    wait until rising_edge(s_clk);
    -- First read all registers
    v_exp := (0 => x"01", others => x"00");
    for i in 0 to 7 loop
      uart_recv(v_data, s_uart_tx);
      assert v_data = v_exp(i)
        report "UART receive error, got 0x" & to_hstring(v_data) & ", expected 0x" & to_hstring(v_exp(i))
        severity failure;
    end loop;
    -- Finally read all registers again after write
    v_exp := (0 => x"01", others => x"FF");
    for i in 0 to 7 loop
      uart_recv(v_data, s_uart_tx);
      assert v_data = v_exp(i)
        report "UART receive error, got 0x" & to_hstring(v_data) & ", expected 0x" & to_hstring(v_exp(i))
        severity failure;
    end loop;
    wait for 200 us;
    report "Simulation finished :-)";
    stop(0);
  end process;

end architecture;
