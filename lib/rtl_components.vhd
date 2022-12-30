library ieee ;
use ieee.std_logic_1164.all;

package components is

  component CC_PLL
  generic (
    REF_CLK         : string := "0";          -- reference clk in MHz
    OUT_CLK         : string := "0";          -- output clk in MHz
    PERF_MD         : string := "UNDEFINED";  -- LOWPOWER, ECONOMY, SPEED (optional, global, setting of Place&Route can be used instead)
    LOW_JITTER      : natural := 1;           -- 0: disable, 1: enable low jitter mode
    CI_FILTER_CONST : natural := 2;           -- optional CI filter constant
    CP_FILTER_CONST : natural := 4            -- optional CP filter constant
  );
  port (
    CLK_REF             : in std_logic;
    CLK_FEEDBACK        : in std_logic;
    USR_CLK_REF         : in std_logic;
    USR_LOCKED_STDY_RST : in std_logic;
    USR_PLL_LOCKED_STDY : out std_logic;
    USR_PLL_LOCKED      : out std_logic;
    CLK270              : out std_logic;
    CLK180              : out std_logic;
    CLK0                : out std_logic;
    CLK90               : out std_logic;
    CLK_REF_OUT         : out std_logic
  );
  end component;

  component CC_PLL_ADV
  generic (
    PLL_CFG_A : std_logic_vector(95 downto 0) := (others => 'X');
    PLL_CFG_B : std_logic_vector(95 downto 0) := (others => 'X')
  );
  port (
    CLK_REF             : in std_logic;
    CLK_FEEDBACK        : in std_logic;
    USR_CLK_REF         : in std_logic;
    USR_LOCKED_STDY_RST : in std_logic;
    USR_SEL_A_B         : in std_logic;
    USR_PLL_LOCKED_STDY : out std_logic;
    USR_PLL_LOCKED      : out std_logic;
    CLK270              : out std_logic;
    CLK180              : out std_logic;
    CLK0                : out std_logic;
    CLK90               : out std_logic;
    CLK_REF_OUT         : out std_logic
  );
  end component;

  component CC_SERDES
  generic (
    SERDES_CFG : string := ""
  );
  port (
    TX_DATA_I             : in std_logic_vector(63 downto 0);
    TX_RESET_I            : in std_logic;
    TX_PCS_RESET_I        : in std_logic;
    TX_PMA_RESET_I        : in std_logic;
    PLL_RESET_I           : in std_logic;
    TX_POWERDOWN_N_I      : in std_logic;
    TX_POLARITY_I         : in std_logic;
    TX_PRBS_SEL_I         : in std_logic_vector(2 downto 0);
    TX_PRBS_FORCE_ERR_I   : in std_logic;
    TX_8B10B_EN_I         : in std_logic;
    TX_8B10B_BYPASS_I     : in std_logic_vector(7 downto 0);
    TX_CHAR_IS_K_I        : in std_logic_vector(7 downto 0);
    TX_CHAR_DISPMODE_I    : in std_logic_vector(7 downto 0);
    TX_CHAR_DISPVAL_I     : in std_logic_vector(7 downto 0);
    TX_ELEC_IDLE_I        : in std_logic;
    TX_DETECT_RX_I        : in std_logic;
    LOOPBACK_I            : in std_logic_vector(2 downto 0);
    CLK_CORE_TX_I         : in std_logic;
    CLK_CORE_RX_I         : in std_logic;
    RX_RESET_I            : in std_logic;
    RX_PMA_RESET_I        : in std_logic;
    RX_EQA_RESET_I        : in std_logic;
    RX_CDR_RESET_I        : in std_logic;
    RX_PCS_RESET_I        : in std_logic;
    RX_BUF_RESET_I        : in std_logic;
    RX_POWERDOWN_N_I      : in std_logic;
    RX_POLARITY_I         : in std_logic;
    RX_PRBS_SEL_I         : in std_logic_vector(2 downto 0);
    RX_PRBS_CNT_RESET_I   : in std_logic;
    RX_8B10B_EN_I         : in std_logic;
    RX_8B10B_BYPASS_I     : in std_logic_vector(7 downto 0);
    RX_EN_EI_DETECTOR_I   : in std_logic;
    RX_COMMA_DETECT_EN_I  : in std_logic;
    RX_SLIDE_I            : in std_logic;
    RX_MCOMMA_ALIGN_I     : in std_logic;
    RX_PCOMMA_ALIGN_I     : in std_logic;
    CLK_REG_I             : in std_logic;
    REGFILE_WE_I          : in std_logic;
    REGFILE_EN_I          : in std_logic;
    REGFILE_ADDR_I        : in std_logic_vector(7 downto 0);
    REGFILE_DI_I          : in std_logic_vector(15 downto 0);
    REGFILE_MASK_I        : in std_logic_vector(15 downto 0);
    RX_DATA_O            : out std_logic_vector(63 downto 0);
    RX_NOT_IN_TABLE_O    : out std_logic_vector(7 downto 0);
    RX_CHAR_IS_COMMA_O   : out std_logic_vector(7 downto 0);
    RX_CHAR_IS_K_O       : out std_logic_vector(7 downto 0);
    RX_DISP_ERR_O        : out std_logic_vector(7 downto 0);
    RX_DETECT_DONE_O     : out std_logic;
    RX_PRESENT_O         : out std_logic;
    TX_BUF_ERR_O         : out std_logic;
    TX_RESETDONE_O       : out std_logic;
    RX_PRBS_ERR_O        : out std_logic;
    RX_BUF_ERR_O         : out std_logic;
    RX_BYTE_IS_ALIGNED_O : out std_logic;
    RX_BYTE_REALIGN_O    : out std_logic;
    RX_RESETDONE_O       : out std_logic;
    RX_EI_EN_O           : out std_logic;
    CLK_CORE_RX_O        : out std_logic;
    CLK_CORE_PLL_O       : out std_logic;
    REGFILE_DO_O         : out std_logic_vector(15 downto 0);
    REGFILE_RDY_O        : out std_logic
  );
  end component;

  component CC_CFG_CTRL
  port (
    DATA  : in std_logic_vector(7 downto 0);
    CLK   : in std_logic;
    EN    : in std_logic;
    RECFG : in std_logic;
    VALID : in std_logic
  );
  end component;

  component CC_FIFO_40K
    generic (
    LOC                 : string := "UNPLACED";  -- Location format: D(0..N-1)X(0..3)Y(0..7) or UNPLACED
    ALMOST_FULL_OFFSET  : std_logic_vector (12 downto 0) := (others => '0');  -- Almost full offset
    ALMOST_EMPTY_OFFSET : std_logic_vector (12 downto 0) := (others => '0');  -- Almost empty offset
    A_WIDTH             : natural := 0;      -- Port A Width
    B_WIDTH             : natural := 0;      -- Port B Width
    RAM_MODE            : string := "SDP";   -- RAM mode: "TPD" or "SDP"
    FIFO_MODE           : string := "SYNC";  -- Write mode: "ASYNC" or "SYNC"
    A_CLK_INV           : std_logic := '0';  -- Inverting Control Pins
    B_CLK_INV           : std_logic := '0';  -- Inverting Control Pins
    A_EN_INV            : std_logic := '0';  -- Inverting Control Pins
    B_EN_INV            : std_logic := '0';  -- Inverting Control Pins
    A_WE_INV            : std_logic := '0';  -- Inverting Control Pins
    B_WE_INV            : std_logic := '0';  -- Inverting Control Pins
    A_DO_REG            : std_logic := '0';  -- Port A Output Register
    B_DO_REG            : std_logic := '0';  -- Port B Output Register
    A_ECC_EN            : std_logic := '0';  -- Port A Error Checking and Correction
    B_ECC_EN            : std_logic := '0'   -- Port B Error Checking and Correction
    );
  port (
    A_ECC_1B_ERR : out std_logic;
    B_ECC_1B_ERR : out std_logic;
    A_ECC_2B_ERR : out std_logic;
    B_ECC_2B_ERR : out std_logic;
    -- FIFO pop port
    A_DO : out std_logic_vector(39 downto 0);
    B_DO : out std_logic_vector(39 downto 0);
  
    A_CLK : in std_logic;
    A_EN  : in std_logic;
    -- FIFO push port
    A_DI : in std_logic_vector(39 downto 0);
    B_DI : in std_logic_vector(39 downto 0);
    A_BM : in std_logic_vector(39 downto 0);
    B_BM : in std_logic_vector(39 downto 0);
  
    B_CLK : in std_logic;
    B_EN  : in std_logic;
    B_WE  : in std_logic;
    -- FIFO control
    F_RST_N : in std_logic;
    F_ALMOST_FULL_OFFSET  : in std_logic_vector(12 downto 0);
    F_ALMOST_EMPTY_OFFSET : in std_logic_vector(12 downto 0);
    -- FIFO status signals
    F_FULL         : out std_logic;
    F_EMPTY        : out std_logic;
    F_ALMOST_FULL  : out std_logic;
    F_ALMOST_EMPTY : out std_logic;
    F_RD_ERROR     : out std_logic;
    F_WR_ERROR     : out std_logic;
    F_RD_PTR       : out std_logic_vector(15 downto 0);
    F_WR_PTR       : out std_logic_vector(15 downto 0)
  );
  end component;

  component CC_CFG_END
  port (
    CFG_END : out std_logic
  );
  end component;

  component CC_BUFG
  port (
    I : in  std_logic;
    O : out std_logic
  );
  end component;


end package components;