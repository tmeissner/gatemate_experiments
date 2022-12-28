DESIGN_NAME := uart_reg
WORK_FILES  := ../rtl/uart_tx.vhd ../rtl/uart_rx.vhd ../rtl/uart_reg.vhd
GM_FILES    := ../../lib/rtl_components.vhd
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

build/${DESIGN_NAME}_00.v ${DESIGN_NAME}.bit: ${DESIGN_NAME}.v ${DESIGN_NAME}.ccf
	cd build && \
	  ${PNRTOOL} -i ../${DESIGN_NAME}.v -o ${DESIGN_NAME}.bit --ccf ../${DESIGN_NAME}.ccf $(PNRFLAGS) \
	  2>&1 | tee p_r-report.txt && \
	  mv ${DESIGN_NAME}*.bit ../${DESIGN_NAME}.bit

syn_sim: ${DESIGN_NAME}.v
	iverilog -g2012 -o tb_${DESIGN_NAME}_syn.vvp ${DESIGN_NAME}.v tb_${DESIGN_NAME}.v /usr/local/share/yosys/gatemate/cells_sim.v
	vvp -N tb_${DESIGN_NAME}_syn.vvp -fst

imp_sim: build/${DESIGN_NAME}_00.v
	iverilog -g2012 -o tb_${DESIGN_NAME}_imp.vvp build/${DESIGN_NAME}_00.v tb_${DESIGN_NAME}.v /opt/cc-toolchain-linux/bin/p_r/cpelib.v
	vvp -N tb_${DESIGN_NAME}_imp.vvp -fst

prog: ${DESIGN_NAME}.bit
	openFPGALoader -b gatemate_evb_jtag $<

clean :
	echo "# Cleaning files"
	rm -rf build ${DESIGN_NAME}.v ${DESIGN_NAME}.bit *.vvp *.fst
