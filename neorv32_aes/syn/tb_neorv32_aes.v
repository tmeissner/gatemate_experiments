`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

`define USE_RAM

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
  localparam clk_half_period = 50;

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

module tb_neorv32_aes;

  // DUT in/out
  reg  clk   = 1'b0;
  reg  rst_n = 1'b1;
  wire [7:0]  led;
  wire [63:0] debug;
  reg uart_rx;
  wire uart_tx;

  // Testbench variables

  // Testbench 1/2 clock period
  localparam clk_half_period = 50;

  // UART period calculation (9600 baud)
  localparam uart_bit_period = 1000000000 / 9600;
  localparam uart_bit_half_period = uart_bit_period/2;

  neorv32_aes UUT (.clk_i(clk), .rst_n_i(rst_n), .led_n_o(led), .debug_o(debug));
//  neorv32_aes UUT (.clk_i(clk), .rst_n_i(rst_n), .led_n_o(led), .uart_tx_o(uart_tx), .uart_rx_i(uart_rx));

  // set dumpfile
  initial begin
    $dumpfile ("tb_neorv32_aes.fst");
    $dumpvars (0, tb_neorv32_aes);
  end
    
  // Setup simulation
  initial begin
    uart_rx = 1'b1;
    #1   rst_n = 1'b0;
    #120 rst_n = 1'b1;
  end

  // Generate 10 mhz clock
  always #clk_half_period clk = !clk;

  // Stimuli generator
  initial 
    forever @(posedge rst_n) begin
    // Simulate for 100 us
    #500_000
//    @(negedge led[0]);
//    #100
    $display ("NEORV32 test finished");
    $finish;
  end

  // Monitor
  initial begin
    $monitor("monitor time=%t ns, rst_n=%b, led=%b, imem.addr=%d, dmem.addr=%h", $time, rst_n, led, debug[31:2], debug[63:32]);
  end

endmodule
