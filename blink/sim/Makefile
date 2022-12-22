DESIGN_NAME := blink
RTL_SRC     := ../rtl/${DESIGN_NAME}.vhd
SIM_SRC     := tb_${DESIGN_NAME}.vhd
VHD_STD     := 08

.PHONY: all compile sim clean

all: sim
compile: tb_${DESIGN_NAME}

tb_${DESIGN_NAME}: ${RTL_SRC} ${SIM_SRC} | work
	@echo "Analyze testbench & design ..."
	ghdl -a --std=${VHD_STD} -fpsl --workdir=work ${RTL_SRC} ${SIM_SRC}
	@echo "Elaborate testbench & design ..."
	ghdl -e --std=${VHD_STD} -fpsl --workdir=work $@

sim: tb_${DESIGN_NAME}
	@echo "Run testbench ..."
	ghdl -r tb_${DESIGN_NAME} --assert-level=error

work:
	mkdir $@

clean:
	@echo "Cleaning simulation files ..."
	rm -rf tb_${DESIGN_NAME} *.o *.json work/
