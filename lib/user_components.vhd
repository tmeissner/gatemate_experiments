-- Async reset synchronizer circuit inspired from
-- Chris Cummings SNUG 2002 paper
--   Synchronous Resets? Asynchronous Resets? 
--   I am so confused!
--   How will I ever know which to use?


library ieee ;
use ieee.std_logic_1164.all;


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


-- Async reset synchronizer circuit inspired from
-- Chris Cummings SNUG 2002 paper
--   Synchronous Resets? Asynchronous Resets? 
--   I am so confused!
--   How will I ever know which to use?


library ieee ;
use ieee.std_logic_1164.all;


entity reset_sync_slv is
generic (
  POLARITY : std_logic := '0'
);
port (
  clk_i : in  std_logic;
  rst_i : in  std_logic_vector;
  rst_o : out std_logic_vector
);
end entity;


architecture sim of reset_sync_slv is

begin

  GEN : for i in rst_i'range generate
    signal s_rst_d : std_logic_vector(1 downto 0);
  begin

  process (clk_i, rst_i(i)) is
  begin
    if (rst_i(i) = POLARITY) then
      s_rst_d <= (others => POLARITY);
    elsif (rising_edge(clk_i)) then
      s_rst_d <= s_rst_d(0) & not POLARITY;
    end if;
  end process;

  rst_o(i) <= s_rst_d(1);

  end generate;

end architecture;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity fifo is
  generic (
    DEPTH  : positive := 16;
    WIDTH  : positive := 16
  );
  port (
    rst_n_i  : in  std_logic;
    clk_i    : in  std_logic;
    -- write
    wen_i    : in  std_logic;
    din_i    : in  std_logic_vector(WIDTH-1 downto 0);
    full_o   : out std_logic;
    werror_o : out std_logic;
    -- read
    ren_i    : in  std_logic;
    dout_o   : out std_logic_vector(WIDTH-1 downto 0);
    empty_o  : out std_logic;
    rerror_o : out std_logic
  );
end entity fifo;


architecture rtl of fifo is

  subtype t_fifo_pnt is natural range 0 to DEPTH-1;
  signal s_write_pnt : t_fifo_pnt;
  signal s_read_pnt  : t_fifo_pnt;

  type t_fifo_mem is array (t_fifo_pnt'low to t_fifo_pnt'high) of std_logic_vector(din_i'range);
  signal s_fifo_mem : t_fifo_mem;

  signal s_almost_full  : boolean;
  signal s_almost_empty : boolean;

  function incr_pnt (data : t_fifo_pnt) return t_fifo_pnt is
  begin
    if (data = t_fifo_mem'high) then
      return 0;
    end if;
    return data + 1;
  end function incr_pnt;

begin

  s_almost_full <= (s_write_pnt = s_read_pnt - 1) or
                   (s_write_pnt = t_fifo_mem'high and s_read_pnt = t_fifo_mem'low);

  s_almost_empty <= (s_read_pnt = s_write_pnt - 1) or
                    (s_read_pnt = t_fifo_mem'high and s_write_pnt = t_fifo_mem'low);

  WriteP : process (rst_n_i, clk_i) is
  begin
    if (not rst_n_i) then
      s_write_pnt <= 0;
      werror_o    <= '0';
    elsif (rising_edge(clk_i)) then
      werror_o <= Wen_i and Full_o;
      if (Wen_i = '1' and Full_o = '0') then
        s_fifo_mem(s_write_pnt) <= Din_i;
        s_write_pnt <= incr_pnt(s_write_pnt);
      end if;
    end if;
  end process WriteP;

  ReadP : process (rst_n_i, clk_i) is
  begin
    if (not rst_n_i) then
      s_read_pnt <= 0;
      rerror_o   <= '0';
    elsif (rising_edge(clk_i)) then
      rerror_o <= Ren_i and Empty_o;
      if (Ren_i = '1' and Empty_o = '0') then
        Dout_o <= s_fifo_mem(s_read_pnt);
        s_read_pnt <= incr_pnt(s_read_pnt);
      end if;
    end if;
  end process ReadP;

  FlagsP : process (rst_n_i, clk_i) is
  begin
    if (rst_n_i = '0') then
      Full_o  <= '0';
      Empty_o <= '1';
    elsif (rising_edge(clk_i)) then
      if (Wen_i = '1') then
        if (Ren_i = '0' and s_almost_full) then
          Full_o <= '1';
        end if;
        Empty_o <= '0';
      end if;
      if (Ren_i = '1') then
        if (Wen_i = '0' and s_almost_empty) then
          Empty_o <= '1';
        end if;
        Full_o <= '0';
      end if;
    end if;
  end process FlagsP;

end architecture;


-- Synchronous AXI stream FIFO based on generic fifo
-- component. Configurable depth and width.


library ieee ;
use ieee.std_logic_1164.all;

library gatemate;
use gatemate.components.all;


entity axis_fifo is
generic (
  DEPTH : positive := 8;
  WIDTH : positive := 8
);
port (
  -- global
  rst_n_i  : in  std_logic;
  clk_i    : in  std_logic;
  -- axis in
  tdata_i  : in  std_logic_vector(WIDTH-1 downto 0);
  tvalid_i : in  std_logic;
  tready_o : out std_logic;
  -- axis aout
  tdata_o  : out std_logic_vector(WIDTH-1 downto 0);
  tvalid_o : out std_logic;
  tready_i : in  std_logic
);
end entity;


architecture rtl of axis_fifo is

  signal s_fifo_wen   : std_logic;
  signal s_fifo_ren   : std_logic;
  signal s_fifo_empty : std_logic;
  signal s_fifo_full  : std_logic;
  signal s_fwft_empty : std_logic;
  signal s_ren        : std_logic;

begin

  fifo : entity work.fifo
  generic map (
    DEPTH  => DEPTH,
    WIDTH  => WIDTH
  )
  port map (
    rst_n_i  => rst_n_i,
    clk_i    => clk_i,
    -- write
    wen_i    => s_fifo_wen,
    din_i    => tdata_i,
    full_o   => s_fifo_full,
    werror_o => open,
    -- read
    ren_i    => s_fifo_ren,
    dout_o   => tdata_o,
    empty_o  => s_fifo_empty,
    rerror_o => open
  );

  -- FWFT logic
  process (clk_i, rst_n_i) is
  begin
    if (not rst_n_i) then
      s_fwft_empty  <= '1';
    elsif (rising_edge(clk_i)) then
      if (s_fifo_ren) then
        s_fwft_empty <= '0';
      elsif (s_ren) then
        s_fwft_empty <= '1';
      end if;
    end if;
  end process;

  s_fifo_ren <= not s_fifo_empty and (s_fwft_empty or s_ren);

  -- AXIS logic
  s_fifo_wen <= tvalid_i and not s_fifo_full;
  s_ren      <= tready_i and not s_fwft_empty;

  tready_o <= not s_fifo_full;

  tvalid_o <= not s_fwft_empty;
end architecture;


-- Synchronous AXI stream FIFO based on GateMate CC_FIFO_40K
-- primitive


library ieee ;
use ieee.std_logic_1164.all;

library gatemate;
use gatemate.components.all;


entity axis_fifo_gm is
generic (
  WIDTH : positive := 8
);
port (
  -- global
  rst_n_i  : in  std_logic;
  clk_i    : in  std_logic;
  -- axis in
  tdata_i  : in  std_logic_vector(WIDTH-1 downto 0);
  tvalid_i : in  std_logic;
  tready_o : out std_logic;
  -- axis aout
  tdata_o  : out std_logic_vector(WIDTH-1 downto 0);
  tvalid_o : out std_logic;
  tready_i : in  std_logic
);
end entity;


architecture rtl of axis_fifo_gm is

  signal s_fifo_wen   : std_logic;
  signal s_fifo_ren   : std_logic;
  signal s_fifo_empty : std_logic;
  signal s_fifo_full  : std_logic;
  signal s_fwft_empty : std_logic;
  signal s_ren        : std_logic;

  signal s_fifo_a_en : std_logic;
  signal s_fifo_b_en : std_logic;
  signal s_fifo_b_we : std_logic;

  signal s_fifo_din  : std_logic_vector(79 downto 0);
  signal s_fifo_dout : std_logic_vector(79 downto 0);

begin

  -- CC_FIFO_40K instance (512x80)
  fifo : CC_FIFO_40K
  generic map (
    LOC                 => "UNPLACED",
    ALMOST_FULL_OFFSET  => (others => '0'),
    ALMOST_EMPTY_OFFSET => (others => '0'),
    A_WIDTH             => WIDTH,  -- 1..80
    B_WIDTH             => WIDTH,  -- 1..80
    RAM_MODE            => "SDP",
    FIFO_MODE           => "SYNC",
    A_CLK_INV           => '0',
    B_CLK_INV           => '0',
    A_EN_INV            => '0',
    B_EN_INV            => '0',
    A_WE_INV            => '0',
    B_WE_INV            => '0',
    A_DO_REG            => '0',
    B_DO_REG            => '0',
    A_ECC_EN            => '0',
    B_ECC_EN            => '0'
    )
  port map(
    A_ECC_1B_ERR => open,
    B_ECC_1B_ERR => open,
    A_ECC_2B_ERR => open,
    B_ECC_2B_ERR => open,
    -- FIFO pop port
    A_DO => s_fifo_dout(39 downto 0),
    B_DO => s_fifo_dout(79 downto 40),
  
    A_CLK => clk_i,
    A_EN  => s_fifo_a_en,
    -- FIFO push port
    A_DI => s_fifo_din(39 downto 0),
    B_DI => s_fifo_din(79 downto 40),
    A_BM => (others => '1'),
    B_BM => (others => '1'),
  
    B_CLK => clk_i,
    B_EN  => s_fifo_b_en,
    B_WE  => s_fifo_b_we,
    -- FIFO control
    F_RST_N => rst_n_i,
    F_ALMOST_FULL_OFFSET  => (others => '0'),
    F_ALMOST_EMPTY_OFFSET => (others => '0'),
    -- FIFO status signals
    F_FULL         => s_fifo_full,
    F_EMPTY        => s_fifo_empty,
    F_ALMOST_FULL  => open,
    F_ALMOST_EMPTY => open,
    F_RD_ERROR     => open,
    F_WR_ERROR     => open,
    F_RD_PTR       => open,
    F_WR_PTR       => open
  );

  s_fifo_b_en <= s_fifo_wen;
  s_fifo_b_we <= s_fifo_wen;
  s_fifo_a_en <= s_fifo_ren;

  -- FWFT logic
  process (clk_i, rst_n_i) is
  begin
    if (not rst_n_i) then
      s_fwft_empty  <= '1';
    elsif (rising_edge(clk_i)) then
      if (s_fifo_ren) then
        s_fwft_empty <= '0';
      elsif (s_ren) then
        s_fwft_empty <= '1';
      end if;
    end if;
  end process;

  s_fifo_ren <= not s_fifo_empty and (s_fwft_empty or s_ren);

  -- AXIS logic
  s_fifo_wen <= tvalid_i and not s_fifo_full;
  s_ren      <= tready_i and not s_fwft_empty;

  tready_o <= not s_fifo_full;
  s_fifo_din(tdata_i'range) <= tdata_i;

  tvalid_o <= not s_fwft_empty;
  tdata_o <= s_fifo_dout(tdata_o'range);

end architecture;
