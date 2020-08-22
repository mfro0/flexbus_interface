SHELL=/bin/bash

TOPLEVEL=tb
TOPLEVEL_FILE=$(TOPLEVEL).vhd
ALT_PATH=-frelaxed-rules --ieee=synopsys -Paltera
NO_BINDING=-Wno-binding
GHDL_OPTS=$(ALT_PATH) $(NO_BINDING)
RUN_OPTS=--ieee-asserts=disable --stop-delta=1000
GHDL=ghdl

ifeq ($(shell uname),Linux)
GTKWAVE=gtkwave
VSIM_PATH=/opt/altera/13.1/modelsim_ase/bin
VSIM=vsim
else
GTKWAVE=gtkwave.exe
VSIM_PATH=/cygdrive/c/opt/altera/13.1/modelsim_ase/win32aloem
VSIM=modelsim.exe
endif
PATH := $(PATH):$(VSIM_PATH)

all: work-obj08.cf

FILES= \
    ../firebee_package.vhd \
	../flexbus_interface.vhd \
    ../flexbus_pll.vhd \
    ../flexbus_register.vhd \
    ../firebee.vhd

#TOPLEVEL_GENERICS=\
#	-gWITH_ACIA_KEYBOARD=\'1\' \
#	-gWITH_ACIA_MIDI=\'1\' \
#	-gWITH_BLITTER=\'1\' \
#	-gWITH_DDR_CTRL=\'1\' \
#	-gWITH_DMA=\'1\' \
#	-gWITH_DSP=\'1\' \
#	-gWITH_FDC=\'1\' \
#	-gWITH_IDECFSD=\'1\' \
#	-gWITH_INTHANDLER=\'1\' \
#	-gWITH_MFP=\'1\' \
#	-gWITH_RTC=\'1\' \
#	-gWITH_SCSI=\'1\' \
#	-gWITH_SOUND=\'1\' \
#	-gWITH_VIDEO=\'1\'

MFP_WAVE_FILE=mfp_test.ghw
MFP_SAVE_FILE=mfp_test.gtkw
VIDEL_WAVE_FILE=videl_test.ghw
VIDEL_SAVE_FILE=videl_test.gtkw

MEM_LIB_PATH=fmf
MEM_LIB=$(MEM_LIB_PATH)/fmf_obj08.cf

mfp: mfp_test.vhd $(FILES)
	$(GHDL) -i $(GHDL_OPTS) --std=08 mfp_test.vhd $(FILES)
	$(GHDL) -m $(GHDL_OPTS) --std=08 mfp_test

videl: videl_test.vhd $(FILES) $(MEM_LIB)
	$(GHDL) -i $(GHDL_OPTS) -Pfmf --std=08 videl_test.vhd $(FILES)
	$(GHDL) -m $(GHDL_OPTS) -Pfmf --std=08 videl_test

MEMORY_MODEL=k4h511638f

$(MEM_LIB): $(MEMORY_MODEL).vhd gen_utils.vhd conversions.vhd
	mkdir -p $(MEM_LIB_PATH)/v08
	$(GHDL) -i $(GHDL_OPTS) --work=fmf --workdir=$(MEM_LIB_PATH)/v08 -Pfmf --std=08 gen_utils.vhd
	$(GHDL) -i $(GHDL_OPTS) --work=fmf --workdir=$(MEM_LIB_PATH)/v08 -Pfmf --std=08 conversions.vhd

.PHONY: ../datetime.vhd
../datetime.vhd:
	(cd ..; tclsh make_datetime.tcl)

.PHONY: run_videl
run_videl: videl
	$(GHDL) -r $(GHDL_OPTS) --std=08 videl_test --wave=$(VIDEL_WAVE_FILE) $(TOPLEVEL_GENERICS) $(RUN_OPTS) 

.PHONY: view_videl
view_videl: videl
	$(GTKWAVE) -a $(VIDEL_SAVE_FILE) $(VIDEL_WAVE_FILE) &

# simulate using modelsim
PATH := /opt/altera/13.1/modelsim_ase/bin:$(PATH)

.PHONY: ms_flexbus
ms_flexbus: $(FILES)
	vlib work
	vcom -2008 $(FILES)
	vcom -2008 flexbus_tb.vhd
	$(VSIM) flexbus_tb

.PHONY: run_mfp
run_mfp: mfp
	$(GHDL) -r $(GHDL_OPTS) --std=08 mfp_test --wave=$(MFP_WAVE_FILE) $(TOPLEVEL_GENERICS) $(RUN_OPTS) 

.PHONY: view_mfp
view_mfp:
	$(GTKWAVE) -a $(MFP_SAVE_FILE) $(MFP_WAVE_FILE) &

.PHONY: clean
clean:
	- rm -f work-obj08.cf $(MEM_LIB) $(WAVE_FILE)

