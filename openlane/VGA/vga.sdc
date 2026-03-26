#===========================================================
# SDC for vga_controller
#===========================================================

#-----------------------------------------------------------
# Default parameters
#-----------------------------------------------------------

if { ![info exists ::env(CLOCK_PERIOD)] } {
    set ::env(CLOCK_PERIOD) 10.0
}

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
# Main clock
#-----------------------------------------------------------

create_clock [get_ports clk] -name clk -period $::env(CLOCK_PERIOD)
puts "\[INFO\]: Creating clock clk on port clk with period $::env(CLOCK_PERIOD) ns"

set_propagated_clock [get_clocks {clk}]
set_clock_uncertainty $::env(SYNTH_CLOCK_UNCERTAINTY) [get_clocks {clk}]
set_clock_transition  $::env(SYNTH_CLOCK_TRANSITION)  [get_clocks {clk}]

puts "\[INFO\]: Clock uncertainty = $::env(SYNTH_CLOCK_UNCERTAINTY) ns"
puts "\[INFO\]: Clock transition  = $::env(SYNTH_CLOCK_TRANSITION) ns"

#-----------------------------------------------------------
# Global electrical constraints
#-----------------------------------------------------------

set_max_transition $::env(MAX_TRANSITION_CONSTRAINT) [current_design]
set_max_fanout     $::env(MAX_FANOUT_CONSTRAINT)     [current_design]

puts "\[INFO\]: Max transition = $::env(MAX_TRANSITION_CONSTRAINT)"
puts "\[INFO\]: Max fanout     = $::env(MAX_FANOUT_CONSTRAINT)"

#-----------------------------------------------------------
# Timing derates
#-----------------------------------------------------------

set_timing_derate -early [expr {1.0 - $::env(SYNTH_TIMING_DERATE)}]
set_timing_derate -late  [expr {1.0 + $::env(SYNTH_TIMING_DERATE)}]

puts "\[INFO\]: Timing derate = [expr {$::env(SYNTH_TIMING_DERATE) * 100.0}] %"

#-----------------------------------------------------------
# Asynchronous reset
#-----------------------------------------------------------

set_false_path -from [get_ports {arst_n}]

#-----------------------------------------------------------
# Synchronous inputs
#-----------------------------------------------------------

# Control / status
set_input_delay -max 2.0 -clock [get_clocks {clk}] [get_ports {enable}]
set_input_delay -min 0.2 -clock [get_clocks {clk}] [get_ports {enable}]

set_input_delay -max 2.0 -clock [get_clocks {clk}] [get_ports {empty}]
set_input_delay -min 0.2 -clock [get_clocks {clk}] [get_ports {empty}]

set_input_delay -max 2.0 -clock [get_clocks {clk}] [get_ports {error_clr}]
set_input_delay -min 0.2 -clock [get_clocks {clk}] [get_ports {error_clr}]

# Pixel data inputs
set_input_delay -max 2.0 -clock [get_clocks {clk}] [get_ports {red[*]}]
set_input_delay -min 0.2 -clock [get_clocks {clk}] [get_ports {red[*]}]

set_input_delay -max 2.0 -clock [get_clocks {clk}] [get_ports {green[*]}]
set_input_delay -min 0.2 -clock [get_clocks {clk}] [get_ports {green[*]}]

set_input_delay -max 2.0 -clock [get_clocks {clk}] [get_ports {blue[*]}]
set_input_delay -min 0.2 -clock [get_clocks {clk}] [get_ports {blue[*]}]

# Configuration inputs
set_input_delay -max 2.0 -clock [get_clocks {clk}] [get_ports {hsync_deact[*]}]
set_input_delay -min 0.2 -clock [get_clocks {clk}] [get_ports {hsync_deact[*]}]

set_input_delay -max 2.0 -clock [get_clocks {clk}] [get_ports {hsync_act[*]}]
set_input_delay -min 0.2 -clock [get_clocks {clk}] [get_ports {hsync_act[*]}]

set_input_delay -max 2.0 -clock [get_clocks {clk}] [get_ports {vsync_deact[*]}]
set_input_delay -min 0.2 -clock [get_clocks {clk}] [get_ports {vsync_deact[*]}]

set_input_delay -max 2.0 -clock [get_clocks {clk}] [get_ports {vsync_act[*]}]
set_input_delay -min 0.2 -clock [get_clocks {clk}] [get_ports {vsync_act[*]}]

#-----------------------------------------------------------
# Input transitions
#-----------------------------------------------------------

set_input_transition -max 0.20 [get_ports {enable}]
set_input_transition -min 0.05 [get_ports {enable}]

set_input_transition -max 0.20 [get_ports {empty}]
set_input_transition -min 0.05 [get_ports {empty}]

set_input_transition -max 0.20 [get_ports {error_clr}]
set_input_transition -min 0.05 [get_ports {error_clr}]

set_input_transition -max 0.20 [get_ports {red[*]}]
set_input_transition -min 0.05 [get_ports {red[*]}]

set_input_transition -max 0.20 [get_ports {green[*]}]
set_input_transition -min 0.05 [get_ports {green[*]}]

set_input_transition -max 0.20 [get_ports {blue[*]}]
set_input_transition -min 0.05 [get_ports {blue[*]}]

set_input_transition -max 0.20 [get_ports {hsync_deact[*]}]
set_input_transition -min 0.05 [get_ports {hsync_deact[*]}]

set_input_transition -max 0.20 [get_ports {hsync_act[*]}]
set_input_transition -min 0.05 [get_ports {hsync_act[*]}]

set_input_transition -max 0.20 [get_ports {vsync_deact[*]}]
set_input_transition -min 0.05 [get_ports {vsync_deact[*]}]

set_input_transition -max 0.20 [get_ports {vsync_act[*]}]
set_input_transition -min 0.05 [get_ports {vsync_act[*]}]

#-----------------------------------------------------------
# Outputs
#-----------------------------------------------------------

set_output_delay -max 2.0 -clock [get_clocks {clk}] [get_ports {rden}]
set_output_delay -min 0.2 -clock [get_clocks {clk}] [get_ports {rden}]

set_output_delay -max 2.0 -clock [get_clocks {clk}] [get_ports {error}]
set_output_delay -min 0.2 -clock [get_clocks {clk}] [get_ports {error}]

set_output_delay -max 2.0 -clock [get_clocks {clk}] [get_ports {ored[*]}]
set_output_delay -min 0.2 -clock [get_clocks {clk}] [get_ports {ored[*]}]

set_output_delay -max 2.0 -clock [get_clocks {clk}] [get_ports {ogreen[*]}]
set_output_delay -min 0.2 -clock [get_clocks {clk}] [get_ports {ogreen[*]}]

set_output_delay -max 2.0 -clock [get_clocks {clk}] [get_ports {oblue[*]}]
set_output_delay -min 0.2 -clock [get_clocks {clk}] [get_ports {oblue[*]}]

set_output_delay -max 2.0 -clock [get_clocks {clk}] [get_ports {h_sync}]
set_output_delay -min 0.2 -clock [get_clocks {clk}] [get_ports {h_sync}]

set_output_delay -max 2.0 -clock [get_clocks {clk}] [get_ports {v_sync}]
set_output_delay -min 0.2 -clock [get_clocks {clk}] [get_ports {v_sync}]

set_output_delay -max 2.0 -clock [get_clocks {clk}] [get_ports {sync}]
set_output_delay -min 0.2 -clock [get_clocks {clk}] [get_ports {sync}]

set_output_delay -max 2.0 -clock [get_clocks {clk}] [get_ports {blank}]
set_output_delay -min 0.2 -clock [get_clocks {clk}] [get_ports {blank}]

# oclk is exported as a divided/toggled signal for VGA timing.
# Since it is not used as an internal propagated clock, constrain it as an output.
set_output_delay -max 2.0 -clock [get_clocks {clk}] [get_ports {oclk}]
set_output_delay -min 0.2 -clock [get_clocks {clk}] [get_ports {oclk}]

#-----------------------------------------------------------
# Output loads
#-----------------------------------------------------------

set_load 0.10 [get_ports {rden}]
set_load 0.10 [get_ports {error}]
set_load 0.10 [get_ports {ored[*]}]
set_load 0.10 [get_ports {ogreen[*]}]
set_load 0.10 [get_ports {oblue[*]}]
set_load 0.10 [get_ports {h_sync}]
set_load 0.10 [get_ports {v_sync}]
set_load 0.10 [get_ports {sync}]
set_load 0.10 [get_ports {blank}]
set_load 0.10 [get_ports {oclk}]

puts "\[INFO\]: vga_controller SDC loaded successfully"