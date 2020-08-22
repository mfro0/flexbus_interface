#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3

# round a floating point result (value) to (decimalplaces)
# decimal places
proc tcl::mathfunc::roundto { value decimalplaces } {
    expr {round(10.0 ** $decimalplaces * $value) / 10.0 ** $decimalplaces}
}


#**************************************************************
# Create Clock
#**************************************************************

set frequency 33.0
set period [expr roundto(1000.0 / $frequency, 3)]

# post_message "period=$period"
# post_message "ddr_period=$ddr_period"

create_clock -period $period -name CLK_MAIN [get_ports {CLK_MAIN}]
#create_clock -period $period -name CLK_33M0_IN [get_ports {CLK_33M0_IN}]
create_clock -period $period -name virt_clk_main

derive_pll_clocks
derive_clock_uncertainty

# set wf [get_clock_info -waveform I_PLL2|*|pll1|clk[1]]
# post_message "wf=$wf"

set_clock_groups -asynchronous \
                 -group { I_PLL1|*|pll1|clk[1] } \
                 -group { I_PLL1|*|pll1|clk[2] } \
                 -group { I_PLL1|*|pll1|clk[3] } \
                 -group { I_PLL1|*|pll1|clk[4] } \
                 -group { I_PLL2|*|pll1|clk[0] \
                          I_PLL2|*|pll1|clk[1] \
                          I_PLL2|*|pll1|clk[2] \
                          I_PLL2|*|pll1|clk[3] \
                          I_PLL2|*|pll1|clk[4] \
                          virt_clk_main \
                          virt_clk_ddr \
                          CLK_MAIN } \
                 -group { I_PLL3|*|pll1|clk[0] } \
                 -group { I_PLL3|*|pll1|clk[1] } \
                 -group { I_PLL3|*|pll1|clk[2] } \
                 -group { I_PLL3|*|pll1|clk[3] } \
                 -group { I_PLL4|*|pll1|clk[0] }


set_false_path -from CLK_MAIN -to I_PLL1|*|pll1|clk[0]

set_multicycle_path -setup -end -from virt_clk_main -to I_PLL2*clk[0] 2
set_multicycle_path -hold -end -from virt_clk_main -to I_PLL2*clk[0] 1

set_multicycle_path -setup -end -from virt_clk_main -to virt_clk_ddr_main 2
set_multicycle_path -hold -end -from virt_clk_main -to virt_clk_ddr_main 1

set_multicycle_path -setup -start -from I_PLL2|*clk[0] -to virt_clk_main 4
set_multicycle_path -hold -start -from I_PLL2|*clk[0] -to virt_clk_main 3

set_multicycle_path -setup -start -from I_PLL2|*clk[4] -to virt_clk_main 2
set_multicycle_path -hold -start -from I_PLL2|*clk[4] -to virt_clk_main 1

set_multicycle_path -setup -start -from I_PLL2|*clk[4] -to CLK_MAIN 2
set_multicycle_path -hold -start -from I_PLL2|*clk[4] -to CLK_MAIN 1

set_multicycle_path -setup -end -from CLK_MAIN -to I_PLL2|*|clk[4] 2
set_multicycle_path -hold -end -from CLK_MAIN -to I_PLL2|*|clk[4] 1

set_multicycle_path -setup -start -from I_PLL2|*|clk[4] -to I_PLL2|*|clk[0] 2
set_multicycle_path -hold -start -from I_PLL2|*|clk[4] -to I_PLL2|*|clk[0] 1



# FlexBus Timing Characteristics
#
# Address, Data and Control Output valid (AD[31:0],
# /FBCS[5:0], R/W, ALE, TSIZ[1:0], /BE, /BWE[3:0],
# /OE and /TBST)                                        : 7,0 ns max
# Address, Data and Control Output valid (AD[31:0],
# /FBCS[5:0], R/W, ALE, TSIZ[1:0], /BE, /BWE[3:0],
# /OE and /TBST)                                        : 1,0 ns min
# Data Input setup                                      : 3,5 ns min
# Data Input hold                                       : 0 ns
# Transfer Acknowledge (/TA) input setup                : 4 ns min
# Transfer Acknowledge (/TA) input hold                 : 0 ns min
#
# (MCF547x Flexbus AC Timing Specifications MCF5475EC.pdf, pg. 13, Table 10)

set flexbus_in_ports [list FB_AD[*] FB_ALE FB_OEn FB_SIZE[*] FB_CSn[*] FB_WRn]
set flexbus_out_ports [list FB_AD[*] FB_TAn]

 foreach in_port $flexbus_in_ports {
    set_input_delay -clock virt_clk_main -add_delay -min 1 $in_port
    set_input_delay -clock virt_clk_main -add_delay -max 7 $in_port
}

foreach out_port $flexbus_out_ports {
    set_output_delay -clock virt_clk_main -add_delay -min  0 $out_port
    set_output_delay -clock virt_clk_main -add_delay -max  3.5 $out_port
}

set ddr_in_ports [list  VDQS[*]]
set ddr_out_ports [list BA[*] CLK_DDR_OUT CLK_DDR_OUTn VA[*] VCASn VRASn VCKE VCSn VDQS[*] VWEn]

foreach in_port $ddr_in_ports {
    set_input_delay -clock virt_clk_ddr_in -add_delay -min -0.25 $in_port
    set_input_delay -clock virt_clk_ddr_in -add_delay -max 0.5 $in_port
}
# set false path for opposite edge VDQS transfers (FIXME: this appears wrong on 2nd sight)
set_false_path -setup -fall_from I_PLL2|*clk[0] -rise_to [get_clocks virt_clk_ddr_main]
set_false_path -setup -rise_from I_PLL2|*clk[0] -rise_to [get_clocks virt_clk_ddr_main]

# set false path for opposite edge VD transfers
set_false_path -setup -fall_from I_PLL2|*clk[0] -rise_to [get_clocks virt_clk_ddr_out]
set_false_path -setup -rise_from I_PLL2|*clk[0] -fall_to [get_clocks virt_clk_ddr_out]

foreach out_port $ddr_out_ports {
    set_output_delay -clock virt_clk_ddr_main -add_delay -min -0.25 $out_port
    set_output_delay -clock virt_clk_ddr_main -add_delay -max 0.5 $out_port
}

# --------------------------- constrain DDR writes
set_output_delay -clock virt_clk_ddr_out -max 0.5 [get_ports VD[*]]
set_output_delay -clock virt_clk_ddr_out -min -0.25 [get_ports VD[*]] -add_delay 
set_output_delay -clock virt_clk_ddr_out -max 0.5 -clock_fall [get_ports VD[*]] -add_delay
set_output_delay -clock virt_clk_ddr_out -min -0.25 -clock_fall [get_ports VD[*]] -add_delay

# set false paths for opposite edge data transfers (rising -> falling and falling -> rising) that Quartus
# Timing Analyzer would (falsely) check (and badly miss timing) by default otherwise
set_false_path -setup -rise_from I_PLL2|*clk[3] -fall_to virt_clk_ddr_out
set_false_path -setup -fall_from I_PLL2|*clk[3] -rise_to virt_clk_ddr_out
set_false_path -hold -rise_from I_PLL2|*clk[3] -rise_to virt_clk_ddr_out
set_false_path -hold -fall_from I_PLL2|*clk[3] -fall_to virt_clk_ddr_out

# ---------------------------- end of DDR write constraints

# ---------------------------- constrain DDR reads
# set_multicycle_path -setup -end -rise_from [get_clocks virt_clk_ddr_in] -rise_to [get_clocks I_PLL2|*|clk[1]] 0
# set_multicycle_path -setup -end -fall_from [get_clocks virt_clk_ddr_in] -fall_to [get_clocks I_PLL2|*|clk[1]] 0

set_multicycle_path -setup -end -from [get_clocks I_PLL2|*|clk[4]] -to [get_clocks virt_clk_ddr_main] 2
set_multicycle_path -hold -end -from [get_clocks I_PLL2|*|clk[4]] -to [get_clocks virt_clk_ddr_main] 1

# set false paths for opposite edge data transfers (rising -> falling and falling -> rising) that Quartus
# Timing Analyzer would (falsely) check (and badly miss timing) by default otherwise
set_false_path -setup -fall_from virt_clk_ddr_in -rise_to [get_clocks I_PLL2|*|clk[1]]
set_false_path -setup -rise_from virt_clk_ddr_in -fall_to [get_clocks I_PLL2|*|clk[1]]
set_false_path -hold -rise_from virt_clk_ddr_in -rise_to [get_clocks I_PLL2|*|clk[1]] 
set_false_path -hold -fall_from virt_clk_ddr_in -fall_to [get_clocks I_PLL2|*|clk[1]]

set_false_path -setup -fall_from I_PLL2|*|clk[1] -rise_to virt_clk_ddr_out
set_false_path -setup -rise_from I_PLL2|*|clk[1] -fall_to virt_clk_ddr_out
set_false_path -hold -rise_from I_PLL2|*|clk[1] -rise_to virt_clk_ddr_out
set_false_path -hold -fall_from I_PLL2|*|clk[1] -fall_to virt_clk_ddr_out

set_input_delay -clock virt_clk_ddr_in -max 0.500 [get_ports VD[*]] -add_delay
set_input_delay -clock virt_clk_ddr_in -min -0.200 [get_ports VD[*]] -add_delay
set_input_delay -clock virt_clk_ddr_in -clock_fall -max 0.500 [get_ports VD[*]] -add_delay
set_input_delay -clock virt_clk_ddr_in -clock_fall -min -0.200 [get_ports VD[*]] -add_delay

#set_input_delay -clock I_PLL2|*|clk[1] -add_delay -min 0 VD[*]
#set_input_delay -clock I_PLL2|*|clk[1] -add_delay -max 0.05 VD[*]

#set_output_delay -clock I_PLL2|*|clk[1] -add_delay -min 0 VDM[*]
#set_output_delay -clock I_PLL2|*|clk[1] -add_delay -max 0.05 VDM[*]

set_multicycle_path -setup -start -from ddr_ctrl:\\gen_ddr_ctrl:i_ddr_ctrl|SR_DDRWR_D_SEL -to VD[*] 2
set_multicycle_path -hold -start -from ddr_ctrl:\\gen_ddr_ctrl:i_ddr_ctrl|SR_DDRWR_D_SEL -to VD[*] 1

