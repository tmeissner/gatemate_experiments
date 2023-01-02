DESIGN_NAME := neorv32_aes

NEORV32_CORE_DIR  := ../../neorv32/rtl/core
NEORV32_PKG       := $(NEORV32_CORE_DIR)/neorv32_package.vhd
NEORV32_APP_SRC   := $(NEORV32_CORE_DIR)/neorv32_application_image.vhd
NEORV32_TEMPLATES := ../../neorv32/rtl/processor_templates

NEORV32_MEM_ENTITIES := \
  $(NEORV32_CORE_DIR)/neorv32_dmem.entity.vhd \
  $(NEORV32_CORE_DIR)/neorv32_imem.entity.vhd

NEORV32_MEM_SRC := \
  $(NEORV32_CORE_DIR)/mem/neorv32_imem.default.vhd \
  $(NEORV32_CORE_DIR)/mem/neorv32_dmem.default.vhd

NEORV32_CORE_SRC := \
  $(NEORV32_CORE_DIR)/neorv32_bootloader_image.vhd \
  $(NEORV32_CORE_DIR)/neorv32_boot_rom.vhd \
  $(NEORV32_CORE_DIR)/neorv32_bus_keeper.vhd \
  $(NEORV32_CORE_DIR)/neorv32_busswitch.vhd \
  $(NEORV32_CORE_DIR)/neorv32_cpu.vhd \
  $(NEORV32_CORE_DIR)/neorv32_cpu_alu.vhd \
  $(NEORV32_CORE_DIR)/neorv32_cpu_bus.vhd \
  $(NEORV32_CORE_DIR)/neorv32_cpu_control.vhd \
  $(NEORV32_CORE_DIR)/neorv32_cpu_cp_bitmanip.vhd \
  $(NEORV32_CORE_DIR)/neorv32_cpu_cp_cfu.vhd \
  $(NEORV32_CORE_DIR)/neorv32_cpu_cp_fpu.vhd \
  $(NEORV32_CORE_DIR)/neorv32_cpu_cp_muldiv.vhd \
  $(NEORV32_CORE_DIR)/neorv32_cpu_cp_shifter.vhd \
  $(NEORV32_CORE_DIR)/neorv32_cpu_decompressor.vhd \
  $(NEORV32_CORE_DIR)/neorv32_cpu_regfile.vhd \
  $(NEORV32_CORE_DIR)/neorv32_debug_dm.vhd \
  $(NEORV32_CORE_DIR)/neorv32_debug_dtm.vhd \
  $(NEORV32_CORE_DIR)/neorv32_fifo.vhd \
  $(NEORV32_CORE_DIR)/neorv32_gpio.vhd \
  $(NEORV32_CORE_DIR)/neorv32_gptmr.vhd \
  $(NEORV32_CORE_DIR)/neorv32_icache.vhd \
  $(NEORV32_CORE_DIR)/neorv32_mtime.vhd \
  $(NEORV32_CORE_DIR)/neorv32_neoled.vhd \
  $(NEORV32_CORE_DIR)/neorv32_onewire.vhd \
  $(NEORV32_CORE_DIR)/neorv32_pwm.vhd \
  $(NEORV32_CORE_DIR)/neorv32_slink.vhd \
  $(NEORV32_CORE_DIR)/neorv32_spi.vhd \
  $(NEORV32_CORE_DIR)/neorv32_sysinfo.vhd \
  $(NEORV32_CORE_DIR)/neorv32_trng.vhd \
  $(NEORV32_CORE_DIR)/neorv32_twi.vhd \
  $(NEORV32_CORE_DIR)/neorv32_uart.vhd \
  $(NEORV32_CORE_DIR)/neorv32_wdt.vhd \
  $(NEORV32_CORE_DIR)/neorv32_wishbone.vhd \
  $(NEORV32_CORE_DIR)/neorv32_xip.vhd \
  $(NEORV32_CORE_DIR)/neorv32_xirq.vhd \
  $(NEORV32_CORE_DIR)/neorv32_cfs.vhd \
  $(NEORV32_CORE_DIR)/neorv32_cfs_aes.vhd \
  $(NEORV32_CORE_DIR)/neorv32_top.vhd

NEORV32_SRC := ${NEORV32_PKG} ${NEORV32_APP_SRC} ${NEORV32_MEM_ENTITIES} \
  ${NEORV32_MEM_SRC} ${NEORV32_CORE_SRC}

AES_DIR   := ../../cryptocores/aes/rtl/vhdl
CRYPTO_SRC := \
  $(AES_DIR)/aes_pkg.vhd \
  $(AES_DIR)/aes_enc.vhd \
  $(AES_DIR)/aes_dec.vhd \
  $(AES_DIR)/aes.vhd \
  $(AES_DIR)/../../../ctraes/rtl/vhdl/ctraes.vhd


WORK_FILES   := ../rtl/${DESIGN_NAME}.vhd
GM_FILES     := ../../lib/rtl_components.vhd

GHDL_FLAGS  := --std=08 --workdir=build -Pbuild
YOSYSPIPE   := -nomx8
# -retime
PNRFLAGS    := -om 3 -cCP on
PNRTOOL     := $(shell which p_r)

.PHONY: all syn imp prog syn_sim imp_sim

all: imp
syn: ${DESIGN_NAME}.v
imp: ${DESIGN_NAME}.bit

build/work-obj08.cf: ${WORK_FILES} build/gatemate-obj08.cf build/neorv32-obj08.cf
	ghdl -a ${GHDL_FLAGS} --work=work ${WORK_FILES}

build/neorv32-obj08.cf: build/gatemate-obj08.cf build/cryptocores-obj08.cf ${NEORV32_SRC}
	ghdl -a $(GHDL_FLAGS) --work=neorv32 ${NEORV32_SRC}

build/cryptocores-obj08.cf: ${CRYPTO_SRC}
	ghdl -a $(GHDL_FLAGS) --work=cryptocores ${CRYPTO_SRC}

build/gatemate-obj08.cf: ${GM_FILES}
	mkdir -p build
	ghdl -a ${GHDL_FLAGS} --work=gatemate ${GM_FILES}

# Synthesis target for implementation
${DESIGN_NAME}.v: build/work-obj08.cf
	yosys -m ghdl -p 'ghdl ${GHDL_FLAGS} --warn-no-binding --no-formal ${DESIGN_NAME}; synth_gatemate -top $(DESIGN_NAME) ${YOSYSPIPE} -vlog $@' \
	  2>&1 | tee build/yosys-report.txt

# Implementation target for FPGA
${DESIGN_NAME}.bit: ${DESIGN_NAME}.v ${DESIGN_NAME}.ccf
	cd build && \
	  ${PNRTOOL} -i ../${DESIGN_NAME}.v -o $@ --ccf ../${DESIGN_NAME}.ccf $(PNRFLAGS) \
	  2>&1 | tee p_r-report.txt && \
	  mv ${DESIGN_NAME}*.bit ../$@

# Post-synthesis simulation target
syn_sim: ${DESIGN_NAME}.v
	iverilog -g2012 -o tb_${DESIGN_NAME}_syn.vvp ${DESIGN_NAME}.v tb_${DESIGN_NAME}.v /usr/local/share/yosys/gatemate/cells_sim.v
	vvp -N tb_${DESIGN_NAME}_syn.vvp -fst

# Post-implementation simulation target
imp_sim: ${DESIGN_NAME}.bit
	iverilog -g2012 -o tb_${DESIGN_NAME}_imp.vvp build/${DESIGN_NAME}_00.v tb_${DESIGN_NAME}.v /opt/cc-toolchain-linux/bin/p_r/cpelib.v
	vvp -N tb_${DESIGN_NAME}_imp.vvp -fst

# FPGA FW load per JTAG
prog: ${DESIGN_NAME}.bit
	openFPGALoader -b gatemate_evb_jtag $<

clean :
	echo "# Cleaning files"
	rm -rf build ${DESIGN_NAME}.v ${DESIGN_NAME}_sim.v ${DESIGN_NAME}.vhd ${DESIGN_NAME}.bit *.vvp *.fst
