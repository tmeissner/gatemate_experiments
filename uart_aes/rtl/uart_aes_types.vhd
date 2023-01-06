library ieee;
use ieee.std_logic_1164.all;


package uart_aes_types is

  type t_axis_ctrl_aes_tuser is record
    start : std_logic;
    key   : std_logic_vector(0 to 127);
    nonce : std_logic_vector(0 to 95);
  end record;

  type t_axis_ctrl_aes_m2s is record
    tuser  : t_axis_ctrl_aes_tuser;
    tdata  : std_logic_vector(0 to 127);
    tvalid : std_logic;
  end record;

  type t_axis_m2s is record
    tdata  : std_logic_vector(0 to 127);
    tvalid : std_logic;
  end record;

  alias t_axis_aes_ctrl_m2s is t_axis_m2s;

  type t_axis_s2m is record
    tready : std_logic;
  end record;

  -- No dout reg necessary, as we simply use AES tdata output
  type t_reg_file is record
    ctrl  : std_logic_vector(7 downto 0);
    key   : std_logic_vector(0 to 127);
    nonce : std_logic_vector(0 to 95);
    din   : std_logic_vector(0 to 127);
  end record;

  constant c_reg_file_init : t_reg_file := (8x"0", 128x"0", 96x"0", 128x"0");

end package;
