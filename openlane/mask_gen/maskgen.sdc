# Clock: 100 MHz
create_clock -name clk -period 10.0 [get_ports clk]

# Clock uncertainty
set_clock_uncertainty 0.2 [get_clocks clk]

# Input delays (apply to all except clk manually)
set_input_delay 2.0 -clock clk [all_inputs]
set_input_delay -min 0.5 -clock clk [all_inputs]

# Remove clock from input delay by overriding it
set_input_delay 0 -clock clk [get_ports clk]

# Output delays
set_output_delay 2.0 -clock clk [all_outputs]
set_output_delay -min 0.5 -clock clk [all_outputs]

# Async reset
set_false_path -from [get_ports arst_n]