`timescale 1 ns/100 ps  // time-unit = 1 ns, precision = 10 ps

// simplified CC_PLL model
module CC_PLL #(
  parameter REF_CLK = "", // e.g. "10.0"
  parameter OUT_CLK = "", // e.g. "50.0"
  parameter PERF_MD = "", // LOWPOWER, ECONOMY, SPEED
  parameter LOW_JITTER = 1,
  parameter CI_FILTER_CONST = 2,
  parameter CP_FILTER_CONST = 4
)(
  input  CLK_REF, CLK_FEEDBACK, USR_CLK_REF,
  input  USR_LOCKED_STDY_RST, USR_SET_SEL,
  output USR_PLL_LOCKED_STDY, USR_PLL_LOCKED,
  output CLK270, CLK180, CLK90, CLK0, CLK_REF_OUT
);

  reg r_pll_clk;
  reg r_user_pll_locked;

  // OUT_FREQ = 10 MHz
  integer clk_half_period = 50;

  initial begin
    r_pll_clk         = 1'b0;
    r_user_pll_locked = 1'b1;
  end

  always #clk_half_period r_pll_clk = ~r_pll_clk;

  assign CLK0 = r_pll_clk;
  assign USR_PLL_LOCKED = r_user_pll_locked;

endmodule


// simplified CC_CFG_END model
module CC_CFG_END (
  output CFG_END
);

  assign CFG_END = 1'b1;

endmodule

module tb_uart_aes;

  // DUT in/out
  reg  clk   = 1'b0;
  reg  rst_n = 1'b1;
  reg  uart_rx;
  wire uart_tx;
  wire [3:0] led_n;

  // Testbench variables
  reg [7:0] tx_data = 8'h0;
  reg [7:0] rx_data = 8'h0;

  // Testbench 1/2 clock period
  localparam clk_half_period = 50;

  // UART period calculation (9600 baud)
  localparam uart_bit_period = 1000000000 / 9600;
  localparam uart_bit_half_period = uart_bit_period/2;

  uart_aes UUT (.clk_i(clk), .rst_n_i(rst_n), .uart_rx_i(uart_rx), .uart_tx_o(uart_tx), .led_n_o(led_n));

  // set dumpfile
  initial begin
    $dumpfile ("tb_uart_aes.fst");
    $dumpvars (0, tb_uart_aes);
  end
    
  // Setup simulation
  initial begin
    uart_rx = 1'b1;
    #1   rst_n = 1'b0;
    #120 rst_n = 1'b1;
  end

  // Generate 10 mhz clock
  always #clk_half_period clk = !clk;

  reg [7:0] write_cmds [0:89];
  reg [7:0] read_data  [0:15];

  // read in test data files
  initial begin
    $readmemh("write_cmds.txt", write_cmds);
    $readmemh("read_data.txt",  read_data);
  end

  // Stimuli generator
  initial 
    forever @(posedge rst_n) begin
    uart_rx = 1'b1;
    #uart_bit_period;
    // start crypto
    for (integer i = 0; i < $size(write_cmds); i = i + 1) begin
      tx_data = write_cmds[i];
      $display ("UART send: 0x%h", tx_data);
      uart_rx = 1'b0;
      #uart_bit_period;
      for (integer i = 0; i <= 7; i = i + 1) begin
        uart_rx = tx_data[i];
        #uart_bit_period;
      end
      uart_rx = 1'b1;
      #uart_bit_period;
      #uart_bit_period;
    end
    // Request read of data out register
    for (integer i = 0; i <= 15; i = i + 1) begin
      tx_data = 8'h40;
      $display ("UART send: 0x%h", tx_data);
      uart_rx = 1'b0;
      #uart_bit_period;
      for (integer i = 0; i <= 7; i = i + 1) begin
        uart_rx = tx_data[i];
        #uart_bit_period;
      end
      uart_rx = 1'b1;
      #uart_bit_period;
      #uart_bit_period;
    end
  end

  // Checker
  initial begin
    @(posedge rst_n)
    for (integer i = 0; i <= 15; i = i + 1) begin
      @(negedge uart_tx)
      #uart_bit_period;
      #uart_bit_half_period;
      for (integer i = 0; i <= 7; i = i + 1) begin
        rx_data[i] = uart_tx;
        #uart_bit_period;
      end
      assert (rx_data == read_data[i])
        $display("UART recv: 0x%h", rx_data);
      else
        $error("UART receive error, got 0x%h, expected 0x%h", rx_data, read_data[i]);
    end
    $display ("UART tests finished");
    $finish;
  end


endmodule
