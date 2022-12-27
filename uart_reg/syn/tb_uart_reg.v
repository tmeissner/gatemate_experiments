`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module tb_uart_reg;

  reg clk = 0;
  reg rst_n;
  reg uart_rx;
  wire uart_tx;
  reg [7:0] tx_data = 0;
  reg [7:0] rx_data = 0;
  wire [3:0] led_n;

  localparam clk_half_period = 50;  
  localparam uart_bit_period = 1000000000 / 9600;
  localparam uart_bit_half_period = uart_bit_period/2;

  uart_reg UUT (.clk_i(clk), .rst_n_i(rst_n), .uart_rx_i(uart_rx), .uart_tx_o(uart_tx), .led_n_o(led_n));

  // set dumpfile
  initial begin
    $dumpfile ("tb_uart_reg.fst");
    $dumpvars (0, tb_uart_reg);
  end
    
  // setup simulation
  initial begin
    rst_n = 1;
    #1  rst_n = 0;
    #20 rst_n = 1;
  end

  // generate clock with 100 mhz
  always #clk_half_period clk = !clk;

  initial begin
    uart_rx = 1'b1;
  end

  initial 
    forever @(posedge rst_n) begin
    uart_rx = 1'b1;
    #uart_bit_period;
    for (integer tx = 0; tx < 16; tx = tx + 1) begin
      tx_data = tx;
      $display ("UART send: 0x%h", tx_data);
      uart_rx = 1'b0;
      #uart_bit_period;
      for (integer i = 0; i < 7; i = i + 1) begin
        uart_rx = tx_data[i];
        #uart_bit_period;
      end
      uart_rx = 1'b1;
      #uart_bit_period;
      #uart_bit_period
      #uart_bit_period;
    end
  end

  // Checker
  always begin
    wait (rst_n)
    for (reg [7:0] rx = 0; rx < 16; rx = rx + 1) begin
      @(negedge uart_tx)
      #uart_bit_period;
      #uart_bit_half_period;
      for (integer i = 0; i < 7; i = i + 1) begin
        rx_data[i] = uart_tx;
        #uart_bit_period;
      end
      assert (rx_data == rx)
        $display("UART recv: 0x%h", rx_data);
      else
        $warning("UART receive error, got 0x%h, expected 0x%h", rx_data, rx);
    end
    $display ("UART tests finished");
    $finish;
  end


endmodule
