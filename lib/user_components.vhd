library ieee ;
use ieee.std_logic_1164.all;


-- Async reset synchronizer circuit inspired from
-- Chris Cummings SNUG 2002 paper
--   Synchronous Resets? Asynchronous Resets? 
--   I am so confused!
--   How will I ever know which to use?

entity reset_sync is
generic (
  POLARITY : std_logic := '0'
);
port (
  clk_i : in  std_logic;
  rst_i : in  std_logic;
  rst_o : out std_logic
);
end entity;


architecture sim of reset_sync is

  signal s_rst_d : std_logic_vector(1 downto 0);

begin

  process (clk_i, rst_i) is
  begin
    if (rst_i = POLARITY) then
      s_rst_d <= (others => POLARITY);
    elsif (rising_edge(clk_i)) then
      s_rst_d <= s_rst_d(0) & not POLARITY;
    end if;
  end process;

  rst_o <= s_rst_d(1);

end architecture;
