# ============================ defines
	../../rtl/memory_system/mem_sys_defines.svh

# ============================ rtl
# Memory system
	../../rtl/memory_system/ram.sv
	../../rtl/memory_system/afifo.sv
	../../rtl/memory_system/buffers.sv
	../../rtl/memory_system/buffers_discharger.sv
	../../rtl/memory_system/buffers_filler.sv
	../../rtl/memory_system/mem_sys.sv

# drawing
	../../rtl/drawing/draw_incremental.sv

# vga
	../../rtl/vga_controller.sv

# wb_slave
	../../rtl/wb_slave/wb_slave.sv
	../../rtl/wb_slave/wb_slave_memory_mapped.sv

# digital top
	../../rtl/dig_top.sv

# ============================ verification
	../wb_master_bfm.sv
  ../lacerta_tb.sv
