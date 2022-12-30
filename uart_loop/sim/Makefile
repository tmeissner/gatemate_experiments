DESIGN_NAME := uart_loop
LIB_SRC     := ../../lib/rtl_components.vhd ../../lib/sim_components.vhd
RTL_SRC     := ../../lib/user_components.vhd ../rtl/uart_tx.vhd ../rtl/uart_rx.vhd ../rtl/${DESIGN_NAME}.vhd
SIM_SRC     := tb_${DESIGN_NAME}.vhd
SIM_FLAGS   := --std=08 -fpsl --workdir=work

.PHONY: all compile sim clean

all: sim
compile: tb_${DESIGN_NAME}

tb_${DESIGN_NAME}: ${LIB_SRC} ${RTL_SRC} ${SIM_SRC}
	mkdir -p work
	@echo "Analyze gatemate library ..."
	ghdl -a ${SIM_FLAGS} --work=gatemate ${LIB_SRC}
	@echo "Analyze testbench & design ..."
	ghdl -a ${SIM_FLAGS} -Pwork ${RTL_SRC} ${SIM_SRC}
	@echo "Elaborate testbench & design ..."
	ghdl -e ${SIM_FLAGS} -Pwork $@

sim: tb_${DESIGN_NAME}
	@echo "Run testbench ..."
	ghdl -r ${SIM_FLAGS} -Pwork tb_${DESIGN_NAME} --assert-level=error

work:
	mkdir $@

clean:
	@echo "Cleaning simulation files ..."
	rm -rf tb_${DESIGN_NAME} *.o work/
