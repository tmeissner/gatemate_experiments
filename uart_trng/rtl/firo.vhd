library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity firo is
generic (
  TOGGLE : boolean := true
);
port (
  frun_i  : in  std_logic;
  fdata_o : out std_logic
);
end entity firo;


architecture rtl of firo is

  -- signal for inverter loop
  signal s_ring : std_logic_vector(15 downto 0);
  signal s_tff  : std_logic;

  -- attributes for synplify synthesis tool to preserve inverter loop
  attribute syn_keep : boolean;
  attribute syn_hier : string;
  attribute syn_hier of rtl    : architecture is "hard";
  attribute syn_keep of s_ring : signal is true;
  attribute syn_keep of s_tff  : signal is true;

begin

  firoring : for index in 1 to 15 generate
    s_ring(index) <= not(s_ring(index - 1));
  end generate;

  s_ring(0) <= (s_ring(15) xor s_ring(14) xor s_ring(7) xor s_ring(6) xor s_ring(5) xor s_ring(4) xor s_ring(2)) and frun_i;

  with_toggle : if TOGGLE generate
    tffP : process(frun_i, s_ring(15)) is
    begin
      if (not frun_i) then
        s_tff <= '0';
      elsif (rising_edge(s_ring(15))) then
        s_tff <= not s_tff;
      end if;
    end process tffP;  
    fdata_o <= s_ring(15) xor s_tff;
  else generate
    fdata_o <= s_ring(15);
  end generate; 


end architecture rtl;
