DESIGN_NAME := blink
WORK_FILES   := ../rtl/blink.vhd
GM_FILES    := ../../lib/components.vhd
GHDL_FLAGS  := --std=08 --workdir=build -Pbuild

.PHONY: all syn

all: syn
syn: ${DESIGN_NAME}.v

work-obj08.cf: ${WORK_FILES} gatemate-obj08.cf
	ghdl -a ${GHDL_FLAGS} --work=work ${WORK_FILES}

gatemate-obj08.cf: ${GM_FILES}
	mkdir -p build
	ghdl -a ${GHDL_FLAGS} --work=gatemate ${GM_FILES}

${DESIGN_NAME}.v: work-obj08.cf
	yosys -m ghdl -p 'ghdl ${GHDL_FLAGS} --no-formal ${DESIGN_NAME}; synth_gatemate -nomx8 -vlog $@' 2>&1 | tee build/yosys-report.txt

clean :
	echo "# Cleaning files"
	rm -rf build ${DESIGN_NAME}.v
