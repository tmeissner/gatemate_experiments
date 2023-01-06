library ieee ;
use ieee.std_logic_1164.all;


package uart_aes_ref is

  procedure cryptData(datain  : in  std_logic_vector(0 to 127);
                      key     : in  std_logic_vector(0 to 127);
                      iv      : in  std_logic_vector(0 to 127);
                      start   : in  boolean;
                      final   : in  boolean;
                      dataout : out std_logic_vector(0 to 127);
                      bytelen : in  integer);

  attribute foreign of cryptData: procedure is "VHPIDIRECT cryptData";

  function swap (datain : std_logic_vector(0 to 127)) return std_logic_vector;

end package;


package body uart_aes_ref is

  procedure cryptData(datain  : in  std_logic_vector(0 to 127);
                      key     : in  std_logic_vector(0 to 127);
                      iv      : in  std_logic_vector(0 to 127);
                      start   : in  boolean;
                      final   : in  boolean;
                      dataout : out std_logic_vector(0 to 127);
                      bytelen : in  integer) is
  begin
    report "VHPIDIRECT cryptData" severity failure;
  end procedure;

  function swap (datain : std_logic_vector(0 to 127)) return std_logic_vector is
    variable v_data : std_logic_vector(0 to 127);
  begin
    for i in 0 to 15 loop
      for y in 0 to 7 loop
        v_data((i*8)+y) := datain((i*8)+7-y);
      end loop;
    end loop;
    return v_data;
  end function;

end package body;
