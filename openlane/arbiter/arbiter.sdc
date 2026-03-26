# SDC for command_arbiter_decoder.v
# Adjust the clock period below to match your target frequency (default: 10.0 ns -> 100 MHz).

# Create primary clock
create_clock -name clk -period 10.0 -waveform {0 5} [get_ports clk]

# Asynchronous reset (arst_n) — do not create timing paths through the async reset pin
set_false_path -from [get_ports arst_n]
set_false_path -to   [get_ports arst_n]

# Example I/O timing templates (commented). Uncomment and edit values to match board-level I/O constraints.
# set_input_delay  -clock clk -max 5.0 [get_ports {uart_mem_we uart_mem_wdata uart_mem_waddr uart_mem_re uart_mem_raddr wb_slave_mem_we wb_slave_mem_wdata wb_slave_mem_wmask wb_slave_mem_waddr wb_slave_mem_re wb_slave_mem_raddr host_wpg_ack host_rpg_ack host_wr_buff_full drw_inc_busy}]
# set_output_delay -clock clk -max 5.0 [get_ports {host_wr_buff_wdata uart_mem_rdata uart_mem_rdy wb_slave_mem_rdata}]

# If there are other clock domains in your design, declare asynchronous groups to avoid false reports:
# set_clock_groups -asynchronous -group { [get_clocks clk] } -group { [get_clocks other_clk] }

# End of SDC