set signals [list]
lappend signals "top.tb_uart_aes.dut.aes_inst.reset_i"
lappend signals "top.tb_uart_aes.dut.aes_inst.clk_i"
lappend signals "top.tb_uart_aes.dut.aes_inst.valid_i"
lappend signals "top.tb_uart_aes.dut.aes_inst.accept_o"
lappend signals "top.tb_uart_aes.dut.aes_inst.start_i"
lappend signals "top.tb_uart_aes.dut.aes_inst.key_i"
lappend signals "top.tb_uart_aes.dut.aes_inst.nonce_i"
lappend signals "top.tb_uart_aes.dut.aes_inst.data_i"
lappend signals "top.tb_uart_aes.dut.aes_inst.valid_o"
lappend signals "top.tb_uart_aes.dut.aes_inst.accept_i"
lappend signals "top.tb_uart_aes.dut.aes_inst.data_o"
set num_added [ gtkwave::addSignalsFromList $signals ]
