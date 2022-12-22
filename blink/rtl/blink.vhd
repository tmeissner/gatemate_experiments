-- This design should display incrementing binary numbers
-- at LED1-LED8 of the GateMate FPGA Starter Kit.


library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity blink is
port (
  clk_i   : in  std_logic;                    -- 10 MHz clock
  rst_n_i : in  std_logic;                    -- SW3 button
  led_n_o : out std_logic_vector(7 downto 0)  -- LED1..LED8
);
end entity blink;


architecture rtl of blink is

  signal s_clk_cnt : unsigned(19 downto 0);
  signal s_clk_en  : boolean;

  signal s_led : unsigned(led_n_o'range);

begin

  process (clk_i, rst_n_i) is
  begin
    if (not rst_n_i) then
      s_clk_cnt <= (others => '0');
    elsif (rising_edge(clk_i)) then
      s_clk_cnt <= s_clk_cnt + 1;
    end if;
  end process;

  s_clk_en <= s_clk_cnt = (s_clk_cnt'range => '1');

  process (clk_i, rst_n_i) is
  begin
    if (not rst_n_i) then
      s_led <= (others => '0');
    elsif (rising_edge(clk_i)) then
      if (s_clk_en) then
        s_led <= s_led + 1;
      end if;
    end if;
  end process;

  led_n_o <= not std_logic_vector(s_led);

end architecture;
