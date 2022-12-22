DESIGN_NAME := blink
SRC_FILES   := ../rtl/blink.vhd
VHD_STD     := 08

.PHONY: all syn

all: ${DESIGN_NAME}_synth.vhd syn
syn: ${DESIGN_NAME}.v

${DESIGN_NAME}.o: ${SRC_FILES}
	ghdl -a --std=${VHD_STD} ${SRC_FILES}

${DESIGN_NAME}_synth.vhd: ${SRC_FILES}
	ghdl --synth --std=$(VHD_STD) ${SRC_FILES} -e ${DESIGN_NAME} > $@

${DESIGN_NAME}.v: ${DESIGN_NAME}.o
	yosys -m ghdl -p 'ghdl --std=${VHD_STD} --no-formal ${DESIGN_NAME}; synth_gatemate -nomx8 -vlog $@'

clean :
	echo "# Cleaning files"
	rm -f *.o work*.cf ${DESIGN_NAME}.v ${DESIGN_NAME}_synth.vhd
