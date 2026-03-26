#===========================================================
# SDC for uart_ip
# Adapted from generic/project constraints
#===========================================================

#-----------------------------------------------------------
# User-adjustable parameters
#-----------------------------------------------------------

# Main clock period in ns
if { ![info exists ::env(CLOCK_PERIOD)] } {
    set ::env(CLOCK_PERIOD) 10.0
}

# Main clock port
set clk_input clk

# Default uncertainty / transition if not provided externally
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

create_clock [get_ports $clk_input] -name clk -period $::env(CLOCK_PERIOD)
puts "\[INFO\]: Creating clock {clk} for port $clk_input with period $::env(CLOCK_PERIOD) ns"

# Clock non-idealities
set_propagated_clock [get_clocks {clk}]
set_clock_uncertainty $::env(SYNTH_CLOCK_UNCERTAINTY) [get_clocks {clk}]
set_clock_transition  $::env(SYNTH_CLOCK_TRANSITION)  [get_clocks {clk}]
puts "\[INFO\]: Clock uncertainty = $::env(SYNTH_CLOCK_UNCERTAINTY) ns"
puts "\[INFO\]: Clock transition  = $::env(SYNTH_CLOCK_TRANSITION) ns"

# Global electrical constraints
set_max_transition $::env(MAX_TRANSITION_CONSTRAINT) [current_design]
set_max_fanout     $::env(MAX_FANOUT_CONSTRAINT)     [current_design]
puts "\[INFO\]: Max transition = $::env(MAX_TRANSITION_CONSTRAINT)"
puts "\[INFO\]: Max fanout     = $::env(MAX_FANOUT_CONSTRAINT)"

# Timing derates
set_timing_derate -early [expr {1.0 - $::env(SYNTH_TIMING_DERATE)}]
set_timing_derate -late  [expr {1.0 + $::env(SYNTH_TIMING_DERATE)}]
puts "\[INFO\]: Timing derate = [expr {$::env(SYNTH_TIMING_DERATE) * 100.0}] %"

#-----------------------------------------------------------
# Reset constraints
#-----------------------------------------------------------

# arst_n is asynchronous reset; do not time it as regular data
set_false_path -from [get_ports {arst_n}]

#-----------------------------------------------------------
# Synchronous register interface inputs
#-----------------------------------------------------------

# These ports are assumed synchronous to clk and driven from
# external logic in the same clock domain.
#
# Adjust these numbers depending on your integration context.

set_input_delay -max 2.0 -clock [get_clocks {clk}] [get_ports {ctl_reg_we}]
set_input_delay -min 0.2 -clock [get_clocks {clk}] [get_ports {ctl_reg_we}]

set_input_delay -max 2.0 -clock [get_clocks {clk}] [get_ports {ctl_reg_wdata[*]}]
set_input_delay -min 0.2 -clock [get_clocks {clk}] [get_ports {ctl_reg_wdata[*]}]

set_input_delay -max 2.0 -clock [get_clocks {clk}] [get_ports {ctl_reg_wmask[*]}]
set_input_delay -min 0.2 -clock [get_clocks {clk}] [get_ports {ctl_reg_wmask[*]}]

set_input_delay -max 2.0 -clock [get_clocks {clk}] [get_ports {st_reg_re}]
set_input_delay -min 0.2 -clock [get_clocks {clk}] [get_ports {st_reg_re}]

set_input_delay -max 2.0 -clock [get_clocks {clk}] [get_ports {st_reg_rmask[*]}]
set_input_delay -min 0.2 -clock [get_clocks {clk}] [get_ports {st_reg_rmask[*]}]

# Input slews for synchronous inputs
set_input_transition -max 0.20 [get_ports {ctl_reg_we}]
set_input_transition -min 0.05 [get_ports {ctl_reg_we}]

set_input_transition -max 0.20 [get_ports {ctl_reg_wdata[*]}]
set_input_transition -min 0.05 [get_ports {ctl_reg_wdata[*]}]

set_input_transition -max 0.20 [get_ports {ctl_reg_wmask[*]}]
set_input_transition -min 0.05 [get_ports {ctl_reg_wmask[*]}]

set_input_transition -max 0.20 [get_ports {st_reg_re}]
set_input_transition -min 0.05 [get_ports {st_reg_re}]

set_input_transition -max 0.20 [get_ports {st_reg_rmask[*]}]
set_input_transition -min 0.05 [get_ports {st_reg_rmask[*]}]

#-----------------------------------------------------------
# Synchronous register interface outputs
#-----------------------------------------------------------

set_output_delay -max 2.0 -clock [get_clocks {clk}] [get_ports {ctl_reg_rdata[*]}]
set_output_delay -min 0.2 -clock [get_clocks {clk}] [get_ports {ctl_reg_rdata[*]}]

set_output_delay -max 2.0 -clock [get_clocks {clk}] [get_ports {st_reg_rdata[*]}]
set_output_delay -min 0.2 -clock [get_clocks {clk}] [get_ports {st_reg_rdata[*]}]

# Output load assumptions
set_load 0.10 [get_ports {ctl_reg_rdata[*]}]
set_load 0.10 [get_ports {st_reg_rdata[*]}]

#-----------------------------------------------------------
# UART asynchronous interface
#-----------------------------------------------------------

# rx is asynchronous to clk; it goes through a 2FF synchronizer.
# Exclude the async input path from standard timing closure.
set_false_path -from [get_ports {rx}]

# tx is a UART serial output, not a clocked synchronous interface
# relative to external capture logic. Exclude it from synchronous
# output timing analysis unless your top-level integration requires
# a specific output delay.
set_false_path -to [get_ports {tx}]

# Optional load on tx
set_load 0.10 [get_ports {tx}]

#-----------------------------------------------------------
# Optional: protect synchronizer first stage
#-----------------------------------------------------------

# If the first synchronizer register instance name is preserved,
# you may constrain it more specifically. Uncomment and adjust
# if synthesis keeps these names.
#
# set_false_path -from [get_ports {rx}] -to [get_pins {rx_2ff_sync/*}]

puts "\[INFO\]: uart_ip SDC loaded successfully"