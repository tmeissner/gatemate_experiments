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
  ../rtl/neorv32_top.vhd

NEORV32_SRC := ${NEORV32_PKG} ${NEORV32_APP_SRC} ${NEORV32_MEM_ENTITIES} \
  ${NEORV32_MEM_SRC} ${NEORV32_CORE_SRC}

AES_DIR   := ../../cryptocores/aes/rtl/vhdl
CRYPTO_SRC := \
  $(AES_DIR)/aes_pkg.vhd \
  $(AES_DIR)/aes_enc.vhd \
  $(AES_DIR)/aes_dec.vhd \
  $(AES_DIR)/aes.vhd \
  $(AES_DIR)/../../../ctraes/rtl/vhdl/ctraes.vhd


WORK_FILES   := ../rtl/${DESIGN_NAME}.vhd tb_${DESIGN_NAME}.vhd
GM_FILES     := ../../lib/rtl_components.vhd ../../lib/sim_components.vhd

SIM_FLAGS   := --std=08 -fpsl --workdir=work -Pwork

.PHONY: all compile sim clean

all: sim
compile: tb_${DESIGN_NAME}


work/work-obj08.cf: ${WORK_FILES} work/gatemate-obj08.cf work/neorv32-obj08.cf
	mkdir -p work
	ghdl -a ${SIM_FLAGS} --work=work ${WORK_FILES}

work/neorv32-obj08.cf: work/gatemate-obj08.cf work/cryptocores-obj08.cf ${NEORV32_SRC}
	mkdir -p work
	ghdl -a $(SIM_FLAGS) --work=neorv32 ${NEORV32_SRC}

work/cryptocores-obj08.cf: ${CRYPTO_SRC}
	mkdir -p work
	ghdl -a $(SIM_FLAGS) --work=cryptocores ${CRYPTO_SRC}

work/gatemate-obj08.cf: ${GM_FILES}
	mkdir -p work
	ghdl -a ${SIM_FLAGS} --work=gatemate ${GM_FILES}

tb_${DESIGN_NAME}: work/gatemate-obj08.cf work/cryptocores-obj08.cf work/neorv32-obj08.cf work/work-obj08.cf
	@echo "Elaborate testbench & design ..."
	ghdl -e ${SIM_FLAGS} -Pwork $@

sim: tb_${DESIGN_NAME}
	@echo "Run testbench ..."
	ghdl -r ${SIM_FLAGS} -Pwork tb_${DESIGN_NAME} --assert-level=error --ieee-asserts=disable --wave=tb_${DESIGN_NAME}.ghw

work:
	mkdir $@

clean:
	@echo "Cleaning simulation files ..."
	rm -rf tb_${DESIGN_NAME} tb_${DESIGN_NAME}.ghw *.o work/
