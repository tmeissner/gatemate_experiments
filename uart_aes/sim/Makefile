DESIGN_NAME := uart_aes

AES_DIR   := ../../cryptocores/aes/rtl/vhdl
CRYPTO_SRC := \
  $(AES_DIR)/aes_pkg.vhd \
  $(AES_DIR)/aes_enc.vhd \
  $(AES_DIR)/aes_dec.vhd \
  $(AES_DIR)/aes.vhd \
  $(AES_DIR)/../../../ctraes/rtl/vhdl/ctraes.vhd

WORK_FILES  := \
  ../rtl/uart_aes_types.vhd \
  ../rtl/uart_tx.vhd \
  ../rtl/uart_rx.vhd \
  ../rtl/uart_ctrl.vhd \
  ../rtl/${DESIGN_NAME}.vhd \
  uart_aes_sim.vhd \
  uart_aes_ref.vhd \
  tb_${DESIGN_NAME}.vhd

GM_FILES   := ../../lib/rtl_components.vhd ../../lib/sim_components.vhd

SIM_SRC     := tb_${DESIGN_NAME}.vhd
SIM_FLAGS   := --std=08 -fpsl --workdir=work -Pwork


.PHONY: all compile sim clean

all: sim
compile: tb_${DESIGN_NAME}

work/work-obj08.cf: ${WORK_FILES} work/gatemate-obj08.cf work/cryptocores-obj08.cf
	mkdir -p work
	ghdl -a ${SIM_FLAGS} --work=work ${WORK_FILES}

work/cryptocores-obj08.cf: ${CRYPTO_SRC}
	mkdir -p work
	ghdl -a $(SIM_FLAGS) --work=cryptocores ${CRYPTO_SRC}

work/gatemate-obj08.cf: ${GM_FILES}
	mkdir -p work
	ghdl -a ${SIM_FLAGS} --work=gatemate ${GM_FILES}

tb_${DESIGN_NAME}: work/work-obj08.cf uart_aes_ref.c
	@echo "Elaborate testbench & design ..."
	ghdl -e ${SIM_FLAGS} -Wl,uart_aes_ref.c -Wl,-lcrypto -Wl,-lssl $@

sim: tb_${DESIGN_NAME}
	@echo "Run testbench ..."
	ghdl -r ${SIM_FLAGS} tb_${DESIGN_NAME} --assert-level=error --ieee-asserts=disable --wave=tb_${DESIGN_NAME}.ghw

work:
	mkdir $@

clean:
	@echo "Cleaning simulation files ..."
	rm -rf tb_${DESIGN_NAME} tb_${DESIGN_NAME}.ghw *.o work/
