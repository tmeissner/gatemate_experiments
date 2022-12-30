library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity firo_ctrl is
generic (
  EXTRACT : boolean := true
);
port (
  -- system 
  clk_i    : in  std_logic;
  rst_n_i  : in  std_logic;
  -- axis in
  tvalid_i : in  std_logic;
  tready_o : out std_logic;
  -- axis out
  tdata_o  : out std_logic_vector(7 downto 0);
  tvalid_o : out std_logic;
  tready_i : in  std_logic;
  -- firo
  frun_o   : out std_logic;
  fdata_i  : in  std_logic
);
end entity firo_ctrl;


architecture rtl of firo_ctrl is

  signal s_clk_counter   : unsigned(4 downto 0);
  signal s_run           : std_logic;
  signal s_firo_valid    : std_logic;

  type t_neumann_state is (BIT1, BIT2, BIT3, BIT4);
  signal s_neumann_state : t_neumann_state;
  signal s_neumann_buffer : std_logic_vector(2 downto 0);

  type t_register_state is (SLEEP, COLLECT, VALID);
  signal s_register_state   : t_register_state;
  signal s_register_enable  : std_logic;
  signal s_register_din     : std_logic_vector(1 downto 0);
  signal s_register_data    : std_logic_vector(8 downto 0);
  signal s_register_counter : unsigned(2 downto 0);
  signal s_register_length  : positive range 1 to 2;

  signal s_data : std_logic_vector(3 downto 0);

begin

  frun_o <= s_run when s_register_state = COLLECT else '0';
  s_data <= s_neumann_buffer & fdata_i;

  ControllerP : process (clk_i) is
  begin
    if (rising_edge(clk_i)) then
      if (s_register_state = SLEEP) then
        s_clk_counter <= (others => '1');
        s_run         <= '0';
        s_firo_valid  <= '0';
      else
        s_clk_counter <= s_clk_counter - 1;
        s_firo_valid  <= '0';
	      if (s_clk_counter = 23 and s_run = '0') then
	        s_run         <= '1';
	        s_clk_counter <= (others => '1');
	      end if;
        if (s_clk_counter = 12 and s_run = '1') then
          s_run <= '0';
          s_clk_counter <= (others => '1');
        end if;
        if (s_clk_counter = 13 and s_run = '1') then
          s_firo_valid <= '1';
        end if;
      end if;
    end if;
  end process ControllerP;

  VON_NEUMANN : if EXTRACT generate
    process (clk_i, rst_n_i) is
    begin
      if (not rst_n_i) then
        s_neumann_state   <= BIT1;
        s_register_enable <= '0';
        s_register_din    <= "00";
      elsif (rising_edge(clk_i)) then
        case s_neumann_state is
      	  when BIT1 =>
  	        s_register_enable <= '0';
  	        if (s_firo_valid) then
  	          s_neumann_buffer(2) <= fdata_i;
  	          s_neumann_state     <= BIT2;
  	        end if;
  	      when BIT2 =>
  	        if (s_firo_valid) then
  	          s_neumann_buffer(1) <= fdata_i;
  	          s_neumann_state     <= BIT3;
  	        end if;
  	      when BIT3 =>
  	        if (s_firo_valid) then
  	          s_neumann_buffer(0) <= fdata_i;
  	          s_neumann_state     <= BIT4;
  	        end if;
          when BIT4 =>
  	        if (s_firo_valid) then
              s_register_enable <= '1';
              s_register_length <= 1;
              s_register_din    <= "00";
  	          s_neumann_state   <= BIT1;
              case (s_data) is
                when x"5" =>
                  s_register_din <= "01";
                when x"1" | x"6" | x"7" =>
                  s_register_length <= 2;
                when x"2" | x"9" | x"b" =>
                  s_register_din    <= "01";
                  s_register_length <= 2;
                when x"4" | x"a" | x"d" =>
                  s_register_din    <= "10";
                  s_register_length <= 2;
                when x"8" | x"c" | x"e" =>
                  s_register_din    <= "11";
                  s_register_length <= 2;
                when x"0" | x"f" =>
                  s_register_enable <= '0';
                when others =>  -- incl. x"3"
                  null;
              end case;
  	        end if;
  	      when others =>
  	        null;
        end case;
      end if;
    end process;
  else generate
    s_register_enable <= s_firo_valid;
    s_register_din(0) <= fdata_i;
    s_register_length <= 1;
  end generate;

  ShiftRegisterP : process (clk_i, rst_n_i) is
  begin
    if (not rst_n_i) then
      s_register_counter <= (others => '1');
      s_register_state   <= SLEEP;
    elsif (rising_edge(clk_i)) then
      case s_register_state is
        when SLEEP =>
          if (tvalid_i) then
            s_register_state   <= COLLECT;
            s_register_data(0) <= s_register_data(8);
          end if;
        when COLLECT =>
          if (s_register_enable) then
            if (s_register_counter = 0) then
              s_register_data  <= s_register_din(1) & s_register_data(6 downto 0) & s_register_din(0);
              s_register_state <= VALID;
            elsif (s_register_counter = 1) then
              if (s_register_length = 1) then
                s_register_data(7 downto 0) <= s_register_data(6 downto 0) & s_register_din(0);
              end if;
              if (s_register_length = 2) then
                s_register_data(7 downto 0) <= s_register_data(5 downto 0) & s_register_din;
                s_register_state <= VALID;
              end if;
            else
              if (s_register_length = 1) then
                s_register_data(7 downto 0) <= s_register_data(6 downto 0) & s_register_din(0);
              else
                s_register_data(7 downto 0) <= s_register_data(5 downto 0) & s_register_din;
              end if;
            end if;
            s_register_counter <= s_register_counter - s_register_length;
          end if;
        when VALID =>
          if (tready_i) then
            s_register_state <= SLEEP;
          end if;
        when others =>
          null;
      end case;
    end if;
  end process ShiftRegisterP;

  tready_o <= '1' when s_register_state = SLEEP else '0';

  tvalid_o <= '1' when s_register_state = VALID else '0';
  tdata_o  <= s_register_data(7 downto 0);

end architecture rtl;
