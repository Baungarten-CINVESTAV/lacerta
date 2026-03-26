# SDC for wb_slave_to_mem_sys_ports.v
# Based on openlane/uart.sdc reference. Adjust numbers as needed.

#-----------------------------------------------------------
# User-adjustable parameters
#-----------------------------------------------------------

if { ![info exists ::env(CLOCK_PERIOD)] } {
    set ::env(CLOCK_PERIOD) 10.0
}

set clk_input wb_clk_i

if { ![info exists ::env(SYNTH_CLOCK_UNCERTAINTY)] } {
    set ::env(SYNTH_CLOCK_UNCERTAINTY) 0.20
}
if { ![info exists ::env(SYNTH_CLOCK_TRANSITION)] } {
    set ::env(SYNTH_CLOCK_TRANSITION) 0.10
}
if { ![info exists ::env(MAX_TRANSITION_CONSTRAINT)] } {
    set ::env(MAX_TRANSITION_CONSTRAINT) 1.50
}
if { ![info exists ::env(MAX_FANOUT_CONSTRAINT)] } {
    set ::env(MAX_FANOUT_CONSTRAINT) 8
}
if { ![info exists ::env(SYNTH_TIMING_DERATE)] } {
    set ::env(SYNTH_TIMING_DERATE) 0.05
}

#-----------------------------------------------------------
# Clock definition
#-----------------------------------------------------------

create_clock [get_ports $clk_input] -name wb_clk -period $::env(CLOCK_PERIOD)
puts "\[INFO\]: Creating clock {wb_clk} for port $clk_input with period $::env(CLOCK_PERIOD) ns"

set_propagated_clock [get_clocks {wb_clk}]
set_clock_uncertainty $::env(SYNTH_CLOCK_UNCERTAINTY) [get_clocks {wb_clk}]
set_clock_transition  $::env(SYNTH_CLOCK_TRANSITION)  [get_clocks {wb_clk}]
puts "\[INFO\]: Clock uncertainty = $::env(SYNTH_CLOCK_UNCERTAINTY) ns"
puts "\[INFO\]: Clock transition  = $::env(SYNTH_CLOCK_TRANSITION) ns"

set_max_transition $::env(MAX_TRANSITION_CONSTRAINT) [current_design]
set_max_fanout     $::env(MAX_FANOUT_CONSTRAINT)     [current_design]
puts "\[INFO\]: Max transition = $::env(MAX_TRANSITION_CONSTRAINT)"
puts "\[INFO\]: Max fanout     = $::env(MAX_FANOUT_CONSTRAINT)"

set_timing_derate -early [expr {1.0 - $::env(SYNTH_TIMING_DERATE)}]
set_timing_derate -late  [expr {1.0 + $::env(SYNTH_TIMING_DERATE)}]
puts "\[INFO\]: Timing derate = [expr {$::env(SYNTH_TIMING_DERATE) * 100.0}] %"

#-----------------------------------------------------------
# Reset / async signals
#-----------------------------------------------------------
# up_soft_reset behaves like a reset; exclude from timing paths
set_false_path -from [get_ports {up_soft_reset}]

# Memory handshake/status signals may be in other domains or asynchronous
set_false_path -from [get_ports {rpg_ack wpg_ack rd_buff_empty wr_buff_full}]

#-----------------------------------------------------------
# Synchronous wishbone interface inputs (assumed synchronous to wb_clk)
#-----------------------------------------------------------
set_input_delay -max 2.0 -clock [get_clocks {wb_clk}] [get_ports {wb_adr_i wb_dat_i wb_we_i wb_sel_i wb_stb_i wb_cyc_i up_en}]
set_input_delay -min 0.2 -clock [get_clocks {wb_clk}] [get_ports {wb_adr_i wb_dat_i wb_we_i wb_sel_i wb_stb_i wb_cyc_i up_en}]

set_input_transition -max 0.20 [get_ports {wb_adr_i wb_dat_i wb_we_i wb_sel_i wb_stb_i wb_cyc_i up_en}]
set_input_transition -min 0.05 [get_ports {wb_adr_i wb_dat_i wb_we_i wb_sel_i wb_stb_i wb_cyc_i up_en}]

# rd_buff_rdata and other memory data/status inputs are assumed asynchronous to wb_clk
# If they are synchronous in your integration, remove the false_path above and add proper input_delay constraints.

#-----------------------------------------------------------
# Synchronous outputs
#-----------------------------------------------------------
set_output_delay -max 2.0 -clock [get_clocks {wb_clk}] [get_ports {wb_dat_o wb_ack_o rpg_busy wpg_busy rd_buff_rden wr_buff_wren}]
set_output_delay -min 0.2 -clock [get_clocks {wb_clk}] [get_ports {wb_dat_o wb_ack_o rpg_busy wpg_busy rd_buff_rden wr_buff_wren}]

# Output load assumptions
set_load 0.10 [get_ports {wb_dat_o wb_ack_o rpg_busy wpg_busy rd_buff_rden wr_buff_wren}]

puts "\[INFO\]: wb_slave_to_mem_sys_ports SDC loaded successfully"