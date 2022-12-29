-- UART register

-- Register file with 8 registers storing values of one byte each.
--
-- The first received byte on the axis in port contains command & address:
--
-- 7   reserved
-- 6:4 register address
-- 3:0 command
--     0x0 read
--     0x1 write
--
-- In case of a write command, the payload has to follow
-- with the next byte.
--
-- In case of a read command, the value of the addressed
-- register is returned on the axis out port.
--
-- Register at address 0 is special. It contains the version
-- and is read-only. Writes to that register are ignored.


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity uart_ctrl is
  port (
    -- globals
    rst_n_i  : in  std_logic;
    clk_i    : in  std_logic;
    -- axis in
    tdata_i  : in  std_logic_vector(7 downto 0);
    tvalid_i : in  std_logic;
    tready_o : out std_logic;
    -- axis out
    tdata_o  : out std_logic_vector(7 downto 0);
    tvalid_o : out std_logic;
    tready_i : in  std_logic
  );
end entity uart_ctrl;


architecture rtl of uart_ctrl is

  type t_state is (IDLE, GET_CMD, RECV_DATA, SEND_DATA);
  signal s_state : t_state;

  subtype t_reg is std_logic_vector(7 downto 0);

  type t_reg_file is array (1 to 7) of t_reg;
  signal s_reg_file : t_reg_file;

  constant c_version : t_reg := x"01";

  signal s_reg_addr : natural range 0 to 7;
  signal s_reg_data : t_reg;

  subtype t_cmd is std_ulogic_vector(3 downto 0);
  constant c_read  : t_cmd := x"0";
  constant c_write : t_cmd := x"1";

  alias a_tdata_cmd  is tdata_i(3 downto 0);
  alias a_tdata_addr is tdata_i(6 downto 4);

begin

  -- Register memory, omitted reset of memory during synthesis
  -- for better RAM detection
  process (clk_i, rst_n_i) is
  begin
    if (not rst_n_i) then
      -- synthesis translate_off
      s_reg_file <= (others => (others => '0'));
      -- synthesis translate_on
      s_reg_data <= (others => '0');
    elsif (rising_edge(clk_i)) then
      -- Write
      if (s_state = RECV_DATA and tvalid_i = '1') then
        -- Ignore writes to version register
        if (s_reg_addr /= 0) then
          s_reg_file(s_reg_addr) <= tdata_i;
        end if;
      end if;
      -- Always read, regardless of write or read command
      if (s_state = GET_CMD) then
        if (s_reg_addr /= 0) then
          s_reg_data <= s_reg_file(s_reg_addr);
        end if;
      end if;
    end if;
  end process;

  -- Control state machine
  process (clk_i, rst_n_i) is
  begin
    if (not rst_n_i) then
      s_state    <= IDLE;
      s_reg_addr <= 0;
    elsif (rising_edge(clk_i)) then
      case s_state is
        when IDLE    =>
          if (tvalid_i) then
            s_state    <= GET_CMD;
            s_reg_addr <= to_integer(unsigned(a_tdata_addr));
          end if;
        when GET_CMD =>
          if (a_tdata_cmd = c_read) then
            s_state <= SEND_DATA;
          elsif (a_tdata_cmd = c_write) then
            s_state <= RECV_DATA;
          else
            s_state <= IDLE;
          end if;
        when RECV_DATA =>
          if (tvalid_i) then
            s_state <= IDLE;
          end if;
        when SEND_DATA =>
          if (tready_i) then
            s_state <= IDLE;
          end if;
        when others =>
          null;
      end case;
    end if;
  end process;

  tready_o <= '1' when s_state = GET_CMD or s_state = RECV_DATA else '0';

  tdata_o  <= c_version when s_reg_addr = 0 else s_reg_data;
  tvalid_o <= '1' when s_state = SEND_DATA else '0';

end architecture;
