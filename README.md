# gatemate_experiments

Ongoing experiments with the Cologne Chip's GateMate FPGA architecture. All experiments are done with teh GateMate FPGA Starter (Eval) Kit.

## Designs

### blink

Simple design which should display a blinking LED waving from LED1-LED8 of the GateMate FPGA Starter Kit. It uses *CC_PLL* & *CC_CFG_END* primitives of the GateMate FPGA.

### uart_reg

Register file which can be accessed through UART. It uses *CC_PLL* & *CC_CFG_END* primitives of the GateMate FPGA. It contains 8 registers storing values of one byte each. The first received byte on the axis in port contains command & address:

* `7  ` reserved
* `6:4` register address
* `3:0` command (`0x0` read, `0x1` write)

In case of a write command, the payload has to follow with the next byte. In case of a read command, the value of the addressed register is returned on the axis out port. Register at address 0 is special. It contains the version and is read-only. Writes to that register are ignored.

## Further Ressources

* [GateMate FPGA](https://www.colognechip.com/programmable-logic/gatemate)
* [GateMate FPGA Eval Board](https://www.colognechip.com/programmable-logic/gatemate-evaluation-board)
* [GHDL VHDL Simulation & Synthesis](https://github.com/ghdl/ghdl)
* [Yosys Synthesis Suite](https://github.com/YosysHQ/yosys)
