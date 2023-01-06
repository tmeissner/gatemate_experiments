library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.env.all;

use work.uart_aes_ref.all;

entity tb_uart_aes is
end entity tb_uart_aes;


architecture sim of tb_uart_aes is

  signal s_clk   : std_logic := '1';
  signal s_rst_n : std_logic := '0';

  signal s_uart_rx : std_logic := '1';
  signal s_uart_tx : std_logic;

  constant c_baudrate  : natural := 9600;
  constant c_period_ns : time := 1_000_000_000 / c_baudrate * ns;

  package uart_aes_sim_inst is new work.uart_aes_sim
    generic map (period_ns => c_period_ns);

  use uart_aes_sim_inst.all;

begin

  dut : entity work.uart_aes
  port map (
    clk_i     => s_clk,
    rst_n_i   => s_rst_n,
    uart_rx_i => s_uart_rx,
    uart_tx_o => s_uart_tx
  );

  s_rst_n <= '1' after 120 ns;
  s_clk   <= not s_clk after 50 ns;

  TestP : process is
    variable v_data      : std_logic_vector(7 downto 0);
    variable v_uart_data : std_logic_vector(0 to 127);
    variable v_key       : std_logic_vector(0 to 127);
    variable v_nonce     : std_logic_vector(0 to 95);
    variable v_in_data   : std_logic_vector(0 to 127);
    variable v_ref_data  : std_logic_vector(0 to 127);
  begin
    wait until s_rst_n;
    wait until rising_edge(s_clk);
    wait for 200 us;
    v_key     := x"0123456789ABCDEF0123456789ABCDEF";
    v_nonce   := x"0123456789ABCDEF01234567";
    aes_setup(v_key, v_nonce, s_uart_rx);
    for i in 0 to 7 loop
      report "Test round " & to_string(i);
      v_in_data := x"0123456789ABCDEF0123456789ABCDEF";
      aes_write(v_in_data, s_uart_rx);
      aes_crypt(s_uart_rx, s_uart_tx);
      aes_read(v_uart_data, s_uart_rx, s_uart_tx);
      -- Calc reference data
      cryptData(swap(v_in_data), swap(v_key), swap(v_nonce & 32x"0"), i=0, i=7, v_ref_data, v_in_data'length/8);
      assert v_uart_data = swap(v_ref_data)
        report "Encryption error: Expected 0x" & to_hstring(swap(v_ref_data)) & ", got 0x" & to_hstring(v_uart_data)
        severity failure;
    end loop;
    wait for 100 us;
    report "Simulation finished without errors";
    stop(0);
  end process;

end architecture;
