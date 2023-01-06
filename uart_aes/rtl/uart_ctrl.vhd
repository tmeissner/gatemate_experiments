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

use work.uart_aes_types.all;


entity uart_ctrl is
  port (
    -- globals
    rst_n_i       : in  std_logic;
    clk_i         : in  std_logic;
    -- axis in
    tdata_i       : in  std_logic_vector(7 downto 0);
    tvalid_i      : in  std_logic;
    tready_o      : out std_logic;
    -- axis out
    tdata_o       : out std_logic_vector(7 downto 0);
    tvalid_o      : out std_logic;
    tready_i      : in  std_logic;
    -- aes out
    ctrl_aes_o    : out t_axis_ctrl_aes_m2s;
    ctrl_aes_i    : in  t_axis_s2m;
    -- aes in
    aes_ctrl_i    : in  t_axis_aes_ctrl_m2s;
    aes_ctrl_o    : out t_axis_s2m
  );
end entity uart_ctrl;


architecture rtl of uart_ctrl is

  type t_state is (IDLE, GET_CMD, RECV_DATA, SEND_DATA);
  signal s_state : t_state;

  signal s_reg_file : t_reg_file;

  signal s_reg_addr : natural range 0 to 7;
  signal s_reg_data : std_logic_vector(7 downto 0);

  subtype t_cmd is std_ulogic_vector(3 downto 0);
  constant c_read  : t_cmd := x"0";
  constant c_write : t_cmd := x"1";

  alias a_tdata_cmd  is tdata_i(3 downto 0);
  alias a_tdata_addr is tdata_i(6 downto 4);

  constant c_ctrl_addr  : natural := 0;
  constant c_key_addr   : natural := 1;
  constant c_nonce_addr : natural := 2;
  constant c_din_addr   : natural := 3;
  constant c_out_addr   : natural := 4;

  constant AES_RESET : natural := 0;  -- Reset key & din registers
  constant CTR_START : natural := 1;  -- 1st round of counter mode
  constant AES_START : natural := 2;  -- start AES engine (cleared with AES_END)
  constant AES_END   : natural := 3;  -- AES engine finished

  type reg_acc_cnt_t is array (natural range <>) of unsigned(3 downto 0);
  signal read_acc_cnt  : reg_acc_cnt_t(0 to 3);
  signal write_acc_cnt : reg_acc_cnt_t(0 to 2);

begin

  -- Register memory
  process (clk_i, rst_n_i) is
  begin
    if (not rst_n_i) then
      s_reg_data    <= (others => '0');
      s_reg_file    <= c_reg_file_init;
      read_acc_cnt  <= (others => x"0");
      write_acc_cnt <= (others => x"0");
    elsif (rising_edge(clk_i)) then
      -- Register write
      if (s_state = RECV_DATA and tvalid_i = '1') then
        case s_reg_addr is
          when 0 => s_reg_file.ctrl <= tdata_i;
                    -- Clear all regs when AES_RESET bit set
                    if (tdata_i(AES_RESET)) then
                      s_reg_file.ctrl  <= (others => '0');
                      s_reg_file.key   <= (others => '0');
                      s_reg_file.nonce <= (others => '0');
                      s_reg_file.din   <= (others => '0');
                      write_acc_cnt    <= (others => x"0");
                      read_acc_cnt     <= (others => x"0");
                    end if;
          when 1 => write_acc_cnt(0) <= write_acc_cnt(0) + 1;
                    s_reg_file.key(to_integer(write_acc_cnt(0))*8 to to_integer(write_acc_cnt(0))*8+7) <= tdata_i;
          when 2 => if (write_acc_cnt(1) = 11) then
                      write_acc_cnt(1) <= x"0";
                    else
                      write_acc_cnt(1) <= write_acc_cnt(1) + 1;
                    end if;
                    s_reg_file.nonce(to_integer(write_acc_cnt(1))*8 to to_integer(write_acc_cnt(1))*8+7) <= tdata_i;
          when 3  => write_acc_cnt(2) <= write_acc_cnt(2) + 1;
                     s_reg_file.din(to_integer(write_acc_cnt(2))*8 to to_integer(write_acc_cnt(2))*8+7) <= tdata_i;
          when others => null;
        end case;
      end if;
      -- Register read
      aes_ctrl_o.tready <= '0';
      if (s_state = GET_CMD and a_tdata_cmd = c_read) then
        case s_reg_addr is
          when 0 => s_reg_data <= s_reg_file.ctrl;
          when 1 => read_acc_cnt(0) <= read_acc_cnt(0) + 1;
                    s_reg_data <= s_reg_file.key(to_integer(read_acc_cnt(0))*8 to to_integer(read_acc_cnt(0))*8+7);
          when 2 => if (read_acc_cnt(1) = 11) then
                      read_acc_cnt(1) <= x"0";
                    else
                      read_acc_cnt(1) <= read_acc_cnt(1) + 1;
                    end if;
                    s_reg_data <= s_reg_file.nonce(to_integer(read_acc_cnt(1))*8 to to_integer(read_acc_cnt(1))*8+7);
          when 3 => read_acc_cnt(2) <= read_acc_cnt(2) + 1;
                    s_reg_data <= s_reg_file.din(to_integer(read_acc_cnt(2))*8 to to_integer(read_acc_cnt(2))*8+7);
          when 4 => read_acc_cnt(3) <= read_acc_cnt(3) + 1;
                    s_reg_data <= aes_ctrl_i.tdata(to_integer(read_acc_cnt(3))*8 to to_integer(read_acc_cnt(3))*8+7);
                    if (read_acc_cnt(3) = 15) then
                      aes_ctrl_o.tready <= aes_ctrl_i.tvalid;
                    end if;
          when others => s_reg_data <= (others => '0');
        end case;
      end if;

      -- Set AES_END when AES out data is valid
      -- Reset when AES out data was accepted (all 16 bytes of AES output data were read)
      if (aes_ctrl_o.tready) then
        s_reg_file.ctrl(AES_END) <= '0';
      elsif (aes_ctrl_i.tvalid) then
        s_reg_file.ctrl(AES_END) <= '1';
      end if;

      -- Reset AES_START & CTR_START when AES engine accepts in data
      if (ctrl_aes_i.tready and s_reg_file.ctrl(AES_START)) then
        s_reg_file.ctrl(AES_START) <= '0';
        s_reg_file.ctrl(CTR_START) <= '0';
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

  tdata_o  <= s_reg_data;
  tvalid_o <= '1' when s_state = SEND_DATA else '0';

  ctrl_aes_o.tuser.start <= s_reg_file.ctrl(CTR_START);
  ctrl_aes_o.tuser.key   <= s_reg_file.key;
  ctrl_aes_o.tuser.nonce <= s_reg_file.nonce;
  ctrl_aes_o.tdata       <= s_reg_file.din;
  ctrl_aes_o.tvalid      <= s_reg_file.ctrl(AES_START);


end architecture;
