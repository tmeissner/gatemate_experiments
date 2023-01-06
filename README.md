# gatemate_experiments

Ongoing experiments with the Cologne Chip's GateMate FPGA architecture. All experiments are done with teh GateMate FPGA Starter (Eval) Kit.

*HINT:*

This project uses external projects (a *neorv32* fork & *cryptocores*), which are redistributed as submodules. To get & nitialize the submodule, please use the `--recursive` option when cloning this repository. Use `git submodule update --recursive` to update the submodule if you already chaked out the main repository.

## Designs

### blink

Simple design which should display a blinking LED waving from LED1-LED8 of the GateMate FPGA Starter Kit. It uses *CC_PLL* & *CC_CFG_END* primitives of the GateMate FPGA.

### neorv32_aes

Try to implement a neorv32 processor with a AES-CTR custom function on the GateMate FPGA. However, it only works in simulation at the moment.

### uart_aes

AES-CTR unit which can be accessed through UART. It uses *CC_PLL* & *CC_CFG_END* primitives of the GateMate FPGA. It contains 5 registers storing values of one byte each. The first received byte on the UART contains command & address:

* `7  ` reserved
* `6:4` register address
* `3:0` command (`0x0` read, `0x1` write)

In case of a write command, the payload has to follow with the next byte. In case of a read command, the value of the addressed register is returned on the axis out port.

Register map:

0. `ctrl ` 1 byte (bit meaning: `0` reset, `1` CTR start, `2` AES start `3` AES finished)
1. `key  ` 16 byte
2. `nonce` 12 byte
3. `din  ` 16 byte
4. `dout ` 16 byte

Content of registers bigger than one byte can be accessed by sending read/write commands for each of the bytes.

Here is a simple example:

First fill the key register with ascending bytes.

```
11 01 11 23 11 45 11 67 11 89 11 AB 11 CD 11 EF 11 01 11 23 11 45 11 67 11 89 11 AB 11 CD 11 EF
```

Next fill the nonce register with ascending bytes.

```
21 01 21 23 21 45 21 67 21 89 21 AB 21 CD 21 EF 21 01 21 23 21 45 21 67
```

Now fill the din register with ascending bytes.

```
31 01 31 23 31 45 31 67 31 89 31 AB 31 CD 31 EF 31 01 31 23 31 45 31 67 31 89 31 AB 31 CD 31 EF
```

Finally, set bit 1 & 2 in control register to start a new AES-CTR operation.

```
01 06
```

Check bit 3 of control register to know when AES-CTR calculation is finished. All other bits of control register are reset when AES-CTR calculation is finished.

`00` returns `80`

Now you can read the encrypted data from the dout register.

```
40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40
```

returns (hopefully)

```
A0 55 A0 62 BC DD C3 4C 33 FE 9F A6 0C FB 6F 2D
```

You can start another AES-CTR round without restarting the counter (nonce register isn't used) ommiting bit 1 of the control register.

```
01 04
```

Control registers bit 0 is used to reset registers 0 - 3.

```
01 01
```

### uart_loop

Simple UART loop with UART RX & TX units and FIFO buffer between. It uses *CC_PLL* & *CC_CFG_END* primitives of the GateMate FPGA. With fifo depth >= 18 Yosys is infering *CC_BRAM_20K* instead of registers.

Beware: The simulation model of *CC_BRAM_20K* seems to be incorrect, so better set fifo depth < 18 or use yosys option `-nobram` when synthesizing the model for post-synthesis & post-implementation simulation.

### uart_reg

Register file which can be accessed through UART. It uses *CC_PLL* & *CC_CFG_END* primitives of the GateMate FPGA. It contains 8 registers storing values of one byte each. The first received byte on the axis in port contains command & address:

* `7  ` reserved
* `6:4` register address
* `3:0` command (`0x0` read, `0x1` write)

In case of a write command, the payload has to follow with the next byte. In case of a read command, the value of the addressed register is returned on the axis out port. Register at address 0 is special. It contains the version and is read-only. Writes to that register are ignored.

### uart_trng

An implementation of a TRNG which allows to read random data from the FPGA via UART. Inclusive a software tool for easy access. Random generation is based on a fibonacci ring oscillator (FiRo) with toggle flip-flop and von Neumann post-processing.

## Further Ressources

* [GateMate FPGA](https://www.colognechip.com/programmable-logic/gatemate)
* [GateMate FPGA Eval Board](https://www.colognechip.com/programmable-logic/gatemate-evaluation-board)
* [GHDL VHDL Simulation & Synthesis](https://github.com/ghdl/ghdl)
* [Yosys Synthesis Suite](https://github.com/YosysHQ/yosys)
