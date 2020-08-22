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
                 -group { i_pll*clk[0] \
                          i_pll*clk[1] \
                          virt_clk_main \
                          CLK_MAIN }


# set_multicycle_path -setup -end -from virt_clk_main -to i_pll1*clk[0] 2
# set_multicycle_path -hold -end -from virt_clk_main -to i_pll1*clk[0] 1

# set_multicycle_path -setup -start -from I_PLL1|*clk[1] -to virt_clk_main 4
# set_multicycle_path -hold -start -from I_PLL1|*clk[1] -to virt_clk_main 3

# set_multicycle_path -setup -end -from CLK_MAIN -to i_pll1|*|clk[1] 4
# set_multicycle_path -hold -end -from CLK_MAIN -to i_pll1|*|clk[1] 3

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

