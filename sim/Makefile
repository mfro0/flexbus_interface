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
	../rtl/vhdl/Firebee/altpll2.vhd \
	../rtl/vhdl/Firebee/Firebee_pkg.vhd \
	../rtl/vhdl/DDR/DDR_CTRL.vhd \
	../rtl/vhdl/WF5380/wf5380_pkg.vhd \
	../rtl/vhdl/WF5380/wf5380_soc_top.vhd \
	../rtl/vhdl/WF5380/wf5380_control.vhd \
	../rtl/vhdl/WF5380/wf5380_registers.vhd \
	../rtl/vhdl/Video/video_top.vhd \
	../rtl/vhdl/Video/video_ctrl.vhd \
	../rtl/vhdl/Video/falcon_dpram.vhd \
	../rtl/vhdl/Video/st_dpram.vhd \
	../rtl/vhdl/Video/fbee_dpram.vhd \
	../rtl/vhdl/Video/lpm_fifoDZ.vhd \
	../rtl/vhdl/Video/lpm_fifo_dc0.vhd \
	../rtl/vhdl/Blitter/Blitter_WF.vhd \
	../rtl/vhdl/DMA/fbee_dma.vhd \
	../rtl/vhdl/DMA/dcfifo1.vhd \
	../rtl/vhdl/DMA/dcfifo0.vhd \
	../rtl/vhdl/Peripherals/ide_cf_sd_rom.vhd \
	../rtl/vhdl/Interrupt/interrupt.vhd \
	../rtl/vhdl/RTC/rtc.vhd \
	../rtl/vhdl/DSP/DSP.vhd \
	../rtl/vhdl/WF_FDC1772_IP/wf1772ip_pkg.vhd \
	../rtl/vhdl/WF_FDC1772_IP/wf1772ip_top.vhd \
	../rtl/vhdl/WF_FDC1772_IP/wf1772ip_top_soc.vhd \
	../rtl/vhdl/WF_FDC1772_IP/wf1772ip_transceiver.vhd \
	../rtl/vhdl/WF_FDC1772_IP/wf1772ip_control.vhd \
	../rtl/vhdl/WF_FDC1772_IP/wf1772ip_registers.vhd \
	../rtl/vhdl/WF_FDC1772_IP/wf1772ip_am_detector.vhd \
	../rtl/vhdl/WF_FDC1772_IP/wf1772ip_crc_logic.vhd \
	../rtl/vhdl/WF_FDC1772_IP/wf1772ip_digital_pll.vhd \
	../rtl/vhdl/WF_UART6850_IP/wf6850ip_top_soc.vhd \
	../rtl/vhdl/WF_UART6850_IP/wf6850ip_receive.vhd \
	../rtl/vhdl/WF_UART6850_IP/wf6850ip_transmit.vhd \
	../rtl/vhdl/WF_UART6850_IP/wf6850ip_ctrl_status.vhd \
	../rtl/vhdl/WF_SND2149_IP/wf2149ip_pkg.vhd \
	../rtl/vhdl/WF_SND2149_IP/wf2149ip_top_soc.vhd \
	../rtl/vhdl/WF_SND2149_IP/wf2149ip_top.vhd \
	../rtl/vhdl/WF_SND2149_IP/wf2149ip_wave.vhd \
	../rtl/vhdl/WF_MFP68901_IP/wf68901ip_pkg.vhd \
	../rtl/vhdl/WF_MFP68901_IP/wf68901ip_top_soc.vhd \
	../rtl/vhdl/WF_MFP68901_IP/wf68901ip_usart_top.vhd \
	../rtl/vhdl/WF_MFP68901_IP/wf68901ip_usart_ctrl.vhd \
	../rtl/vhdl/WF_MFP68901_IP/wf68901ip_usart_rx.vhd \
	../rtl/vhdl/WF_MFP68901_IP/wf68901ip_usart_tx.vhd \
	../rtl/vhdl/WF_MFP68901_IP/wf68901ip_timers.vhd \
	../rtl/vhdl/WF_MFP68901_IP/wf68901ip_interrupts.vhd \
	../rtl/vhdl/WF_MFP68901_IP/wf68901ip_gpio.vhd \
	../rtl/vhdl/Firebee/altpll4.vhd \
	../rtl/vhdl/Firebee/altpll3.vhd \
	../rtl/vhdl/Firebee/altpll1.vhd \
	../rtl/vhdl/Firebee/altpll_reconfig1.vhd \
	../rtl/vhdl/Firebee/ddr_vdm_out.vhd \
	../rtl/vhdl/Firebee/ddr_vd_bidir.vhd \
	../rtl/vhdl/Firebee/rgb_out.vhd  \
	k4h511638f.vhd \
	dual_ddr.vhd \
	../rtl/vhdl/Firebee/flexbus_interface.vhd \
	../rtl/vhdl/Firebee/Firebee_Top.vhd \

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

.PHONY: ms_videl
ms_videl: $(FILES)
	vlib fmf
	vcom -work fmf -2008 conversions.vhd gen_utils.vhd
	vlib work
	vcom -2008 $(FILES)
	vcom -2008 videl_test.vhd
	$(VSIM) -gVERSION=0 -gWITH_ACIA_KEYBOARD=false -gWITH_ACIA_MIDI=false -gWITH_BLITTER=false \
		    -gWITH_DMA=false -gWITH_SCSI=false -gWITH_SOUND=false -gWITH_FDC=false -gWITH_RTC=false videl_test

.PHONY: run_mfp
run_mfp: mfp
	$(GHDL) -r $(GHDL_OPTS) --std=08 mfp_test --wave=$(MFP_WAVE_FILE) $(TOPLEVEL_GENERICS) $(RUN_OPTS) 

.PHONY: view_mfp
view_mfp:
	$(GTKWAVE) -a $(MFP_SAVE_FILE) $(MFP_WAVE_FILE) &

.PHONY: clean
clean:
	- rm -f work-obj08.cf $(MEM_LIB) $(WAVE_FILE)

