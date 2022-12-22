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
  port map (
    clk_i   => s_clk,
    rst_n_i => s_rst_n,
    led_n_o => s_led_n
  );

  s_rst_n <= '1' after 1.2 us;
  s_clk   <= not s_clk after 500 ns;

  -- Let's test the first 8 values of LED output
  process is
  begin
    wait until s_rst_n;
    wait until rising_edge(s_clk);
    for i in 0 to 7 loop
      report "LED: " & to_hstring(not s_led_n);
      assert to_integer(unsigned(not s_led_n)) = i
        report "LED error, got 0x" & to_hstring(s_led_n) & ", expected 0x" & to_hstring(to_unsigned(255-i, 8))
        severity failure;
      wait until s_led_n'event;
    end loop;
    stop(0);
  end process;

end architecture;
