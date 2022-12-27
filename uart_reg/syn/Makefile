DESIGN_NAME := uart_reg
WORK_FILES   := ../rtl/uart_reg.vhd
GM_FILES    := ../../lib/components.vhd
GHDL_FLAGS  := --std=08 --workdir=build -Pbuild
YOSYSPIPE   := -nomx8 -luttree -retime
PNRFLAGS    := -sp off -om 2 -cCP on
PNRTOOL     := $(shell which p_r)

.PHONY: all syn imp prog

all: imp
syn: ${DESIGN_NAME}.v
imp: ${DESIGN_NAME}.bit

build/work-obj08.cf: ${WORK_FILES} build/gatemate-obj08.cf
	ghdl -a ${GHDL_FLAGS} --work=work ${WORK_FILES}

build/gatemate-obj08.cf: ${GM_FILES}
	mkdir -p build
	ghdl -a ${GHDL_FLAGS} --work=gatemate ${GM_FILES}

${DESIGN_NAME}.v: build/work-obj08.cf
	yosys -m ghdl -p 'ghdl ${GHDL_FLAGS} --no-formal ${DESIGN_NAME}; synth_gatemate -top $(DESIGN_NAME) ${YOSYSPIPE} -vlog $@' \
	  2>&1 | tee build/yosys-report.txt

${DESIGN_NAME}.bit: ${DESIGN_NAME}.v ${DESIGN_NAME}.ccf
	cd build && \
	  ${PNRTOOL} -i ../${DESIGN_NAME}.v -o $@ --ccf ../${DESIGN_NAME}.ccf $(PNRFLAGS) \
	  2>&1 | tee p_r-report.txt && \
	  mv ${DESIGN_NAME}*.bit ../$@

prog: ${DESIGN_NAME}.bit
	openFPGALoader -b gatemate_evb_jtag $<

clean :
	echo "# Cleaning files"
	rm -rf build ${DESIGN_NAME}.v ${DESIGN_NAME}.bit
