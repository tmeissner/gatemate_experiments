library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.env.all;


entity tb_blink is
end entity tb_blink;


architecture sim of tb_blink is

  signal s_clk   : std_logic := '1';
  signal s_rst_n : std_logic := '0';

  signal s_led_n : std_logic_vector(7 downto 0);

begin

  dut : entity work.blink
  generic map (
    SIM => 1
  )
  port map (
    clk_i   => s_clk,
    rst_n_i => s_rst_n,
    led_n_o => s_led_n
  );

  s_rst_n <= '1' after 120 ns;
  s_clk   <= not s_clk after 50 ns;

  -- Let's test one complete rotate of LED output
  TestP : process is
    variable v_led_n : std_logic_vector(s_led_n'range) := x"FE";
  begin
    wait until s_rst_n;
    wait until rising_edge(s_clk);
    for i in 0 to 7 loop
      report "LED: " & to_hstring(s_led_n);
      assert s_led_n = v_led_n
        report "LED error, got 0x" & to_hstring(s_led_n) & ", expected 0x" & to_hstring(v_led_n)
        severity failure;
      wait until s_led_n'event;
      v_led_n := v_led_n(6 downto 0) & v_led_n(7);
    end loop;
    report "Simulation finished :-)";
    stop(0);
  end process;

end architecture;
