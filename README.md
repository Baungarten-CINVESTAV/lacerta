<p align="center">
  <img src="documentation_mkdoc/docs/img/Logo_Black_background_white.svg" alt="Mifral logo" width="220">
</p>

# Lacerta: Open Hardware Interface Engine for Embedded Systems

![Lacerta logo](documentation_mkdoc/docs/img/Lacerta2.png)

## Project Overview

**Lacerta** is an open-source hardware platform that enables the rapid creation of graphical interfaces for embedded systems using custom silicon.

**The whole documentation can be found** [**here**](https://baungarten-cinvestav.github.io/lacerta/).

The system allows developers to design graphical interfaces using a graphical configuration tool and deploy them directly to hardware implemented in a custom ASIC integrated with the Caravel SoC platform. The hardware renders the interface in real time and outputs the result to SPI-driven TFT/OLED screens commonly used in embedded devices.

The generated interface may include visual components such as:

- Buttons
- Horizontal and vertical bars
- Numeric indicators
- Status indicators
<p align="center">
<img src="documentation_mkdoc/docs/img/sample_icons.jpg">
</p>
<p align="center">
<b>Figure 1.</b> Examples of graphical components supported by Lacerta, including buttons, horizontal and vertical bars, numeric indicators, graphics, and status indicators used to visualize real-time system data.
</p>

The ASIC receives information via UART streams and supports two main modes of operation for updating the display:

1. **Direct Mode:** Data received via UART is sent directly to the user project area. In this mode, the values are updated on the SPI TFT/OLED screen with minimal latency, ideal for simple or time-critical updates.

2. **Processing Mode:** Data from UART is first routed to the integrated RISC-V core, where any mathematical operations, functions, or custom logic can be applied. After processing, the results are sent to the user project area to update the display. This mode is suitable for applications requiring data manipulation or more complex interface logic.

This flexible architecture allows Lacerta to efficiently manage multiple inputs and screen objects using a single UART protocol, adapting to both straightforward and advanced use cases. Any other signal types must be converted to UART beforehand by external interface circuitry or preprocessing devices.

<p align="center">
<img src="documentation_mkdoc/docs/img/flow_sensor_lacertav2.png">
</p>
<p align="center">
<b>Figure 2.</b> Lacerta system concept: signals are processed by the Lacerta ASIC to generate the custom graphical HMI displayed on SPI-driven TFT/OLED displays for compact embedded installations.
</p>


# System Architecture Summary

The Lacerta platform is an open-source embedded graphics system built from four main parts: custom silicon, board-level hardware, firmware/control logic, and interface software. Together, these layers allow a host system to load graphics data, update interface objects, and drive a small SPI-connected display efficiently.

## Core architecture
Lacerta platform is a custom ASIC implemented in the **SKY130 process** and integrated inside the **Caravel user project area**. This subsystem realizes the hardware graphics engine that receives interface commands, updates the internal display state, and generates the output stream presented on the display.

The Lacerta ASIC follows a memory-centric architecture. Configuration data and runtime values enter the system through **UART**. Depending on the selected operating mode, the received data can be forwarded directly to the user project area or first processed by the embedded **Caravel RISC-V** processor. Internal transactions are routed through the **Wishbone interconnect** to the rendering logic, which updates the frame contents stored in memory. The display output block then reads that memory and continuously converts it into the signal required by the connected **SPI TFT/OLED display**.

The ASIC includes the following main modules:

- the external SRAM interface,
- the TFT SPI interface,
- the UART command interface,
- the Wishbone interface,
- the screen update logic,
- the drawing logic,
- and the shared memory subsystem.


<p align="center">
<img src="documentation_mkdoc/docs/img/lacerta_blockd_vfinal.png">
</p>
<p align="center">
<b>Figure 3.</b> Block diagram of the Lacerta ASIC inside the Caravel environment. The figure shows how UART data and the embedded Caravel RISC-V processor interact through the Wishbone-connected control path, rendering logic, and memory subsystem; the updated frame data is then read by the display output block to drive the screen.
</p>


## Main subsystems

### Memory subsystem

The memory subsystem manages buffered access to external SRAM. It uses FIFOs, read/write buffering, and arbitration logic so several blocks can share memory safely without needing to handle low-level SRAM timing directly.

### Screen output subsystem

The screen path reads pixel data from memory and converts it into SPI transactions for the display. It supports TFT initialization, full or partial region refreshes, and a color lookup mechanism that maps compact pixel codes to RGB565 values. This reduces memory usage and makes repeated HMI colors efficient to store.

### Drawing subsystem

The drawing logic updates only the parts of the image that change. The `mask_generator` reads current pixel data, modifies selected regions based on object type, writes the result back to SRAM, and then triggers a refresh of the affected rectangle. This makes the system well suited for HMI elements such as bars, graphs, booleans, and segmented displays.

### Command and control subsystem

The control path is coordinated by `command_arbiter_decoder`, which receives transactions from UART and Wishbone interfaces and turns them into actions such as memory access, object redraws, screen refreshes, color-table updates, and reset/control operations.

### UART and Wishbone interfaces

UART provides an external host-facing command port for loading assets, configuring the display, and triggering updates. Wishbone provides processor-oriented access to both control registers and shared memory, allowing the embedded Caravel processor or another SoC master to work with the same graphics system.

## Typical operation

In normal use, a host first loads graphics assets or configuration data into SRAM. The display is initialized, then object updates are triggered through UART or processor commands. The drawing engine modifies only the required image region in memory, and the screen subsystem refreshes only that changed rectangle on the TFT. This avoids full-screen redraws and improves efficiency for dynamic interfaces.

## Lacerta board role

The Lacerta Board packages the SoC with the supporting hardware needed for practical use, including power regulation, clocking, USB-to-serial connectivity, SPI Flash support, GPIO access, and display/peripheral connections. It serves as the physical platform for development, testing, and demonstration of the Lacerta graphics architecture.

# System Development

The development of the Lacerta platform spans the complete hardware and software realization flow, from digital design and verification to physical implementation and system-level integration. This section describes the main stages used to transform the Lacerta concept into a functional platform, including RTL design, verification, layout generation, gate-level validation, PCB development, and the creation of the interface design software.

Together, these activities define the engineering workflow followed to implement, test, and deploy Lacerta as an open-source embedded graphical interface system. Each subsection highlights a different part of this process and explains how the individual development tasks contribute to the final platform.

## Lacerta RTL

### System Purpose

The system is designed to display graphical HMI content on a TFT screen and to update only the screen regions that change.

At a functional level, the system must:

- receive commands and image-related data,
- store image bytes and mask bytes in external SRAM,
- modify selected objects inside the stored image,
- fetch the corresponding pixel data,
- convert logical pixel information into display colors,
- and transmit the final bytes to the TFT controller.

The design is organized around a shared memory architecture. Instead of each module touching the SRAM directly, all active clients use a common memory subsystem with buffered read and write channels, as shown in the figure below.

<p align="center">
<img src="documentation_mkdoc/docs/img/lacerta_blockd_vfinal.png">
</p>
<p align="center">
<b>Figure 4.</b> Block diagram of the Lacerta ASIC inside the Caravel environment. The figure shows how UART data and the embedded Caravel RISC-V processor interact through the Wishbone-connected control path, rendering logic, and memory subsystem; the updated frame data is then read by the display output block to drive the screen.
</p>

### High-Level Functional Flow

The complete display flow is:

1. A host or processor sends control commands or image data.
2. The command path decodes the request and either:
   - writes data into the shared memory system,
   - updates display-related configuration,
   - or starts a drawing operation.
3. The memory subsystem transfers bytes between internal buffers and external SRAM.
4. If an HMI object changes, `mask_generator` reads the corresponding image region, updates the stored bytes, and writes the modified data back into SRAM.
5. Once the image region is ready, `screen_system` requests the affected window from memory.
6. `tft_control_fsm` streams TFT commands and pixel bytes through `spi_master`.
7. The TFT receives only the updated region instead of a full-screen redraw.

This makes the system well suited for dashboards, indicators, bars, graphs, and symbolic objects that change frequently in small areas.

### Top-Level Integration (User Project Wrapper)

#### `dig_top.v` 

`dig_top` is the main integration point of the RTL system.
It connects:
- the UART interface,
- the Wishbone interface,
- the external SRAM,
- the TFT SPI pins,
- the shared memory subsystem,
- the drawing engine,
- and the display engine.
Its main functional job is to route requests from several clients into the memory system and to coordinate which subsystem is producing or consuming pixel data.

The clients connected to the shared memory system are:

- UART host write path,
- UART host read path,
- screen-system read path,
- drawing-engine read path,
- drawing-engine write path,
- Wishbone memory read path,
- Wishbone memory write path.

Inside `dig_top`, each client is assigned to a dedicated buffer slot. The top-level combinational logic packs the individual requests into the vectors expected by `mem_sys`.

`dig_top` also derives the frame-update rectangle used by the display block:

- `frame_st_x`
- `frame_end_x`
- `frame_width`
- `frame_st_y`
- `frame_end_y`
- `frame_height`
- `frame_st_pix`

These values are taken from the drawing object parameters so that, after a drawing operation, the correct screen region can be refreshed automatically.

Another important top-level task is Wishbone routing. `dig_top` chooses whether a Wishbone transaction goes to:

- `wb_slave_memory_mapped` for control/MMIO accesses,
- or `wb_slave_to_mem_sys_ports` for direct SRAM-backed data accesses.

### End-to-End Operation Examples

#### Example 1: Loading image data from UART

1. The host sends UART packets.
2. `uart_ip_memory_mapped` converts them into internal writes.
3. `command_arbiter_decoder` interprets those writes as host memory-transfer commands.
4. The host write buffer receives the data bytes.
5. `mem_sys` schedules the write burst.
6. `buffers_discharger` sends the bytes to SRAM through `sram_controller`.

#### Example 2: Updating an HMI object

1. The host or processor writes object parameters.
2. `command_arbiter_decoder` stores width, height, position, object value, and memory addresses.
3. A start command asserts `drw_inc_start`.
4. `mask_generator` begins a read-modify-write sequence.
5. The old bytes are fetched from SRAM through `mem_sys`.
6. The updated bytes are written back to SRAM through `mem_sys`.
7. `mask_generator` asserts `ss_start`.
8. `screen_system` refreshes the affected rectangle on the TFT.

#### Example 3: Refreshing the sidebar

1. A control write asserts `ss_ld_sidebar`.
2. `tft_control_fsm` programs the sidebar coordinates into the TFT.
3. It requests the corresponding SRAM burst.
4. Two bytes per pixel are read.
5. Those bytes are transmitted directly through `spi_master`.

### Main Functional Role of Each Major Module

- `dig_top`: integrates the whole system and routes all subsystem interfaces.
- `command_arbiter_decoder`: converts UART/Wishbone commands into internal control actions.
- `uart_ip_memory_mapped`: converts UART packets into internal memory-mapped transactions.
- `wb_slave_memory_mapped`: converts Wishbone MMIO accesses into control transactions.
- `wb_slave_to_mem_sys_ports`: converts Wishbone data accesses into shared-memory bursts.
- `mem_sys`: arbitrates shared access to external SRAM.
- `buffers`: stores temporary read and write data for all clients.
- `buffers_filler`: fills read buffers from SRAM.
- `buffers_discharger`: empties write buffers into SRAM.
- `sram_controller`: drives the physical SRAM pins.
- `mask_generator`: updates image regions according to HMI object logic.
- `screen_system`: top display block for TFT output.
- `tft_control_fsm`: performs TFT initialization and region-based pixel transfer.
- `color_mapping_table`: converts compact pixel codes into RGB565 colors.
- `spi_master`: serializes commands and pixel bytes onto the TFT SPI bus.


## Lacerta Verification
A layered verification strategy was used to validate Lacerta from block level up to full-system behavior. The intent was not only to prove that individual modules operate correctly in isolation, but also to verify that the complete command, memory, drawing, and display paths remain coherent when exercised through the same interfaces used in deployment.

At the block level, dedicated environments were created for the UART front end, the shared memory subsystem, the Wishbone adapters, the command decoder, and the display-related logic. These environments focused on local protocol correctness, handshake legality, data stability, and forward progress. The later sections of this document list the principal checks captured for each block.

At the system level, the main integration environment is `verif/dig_top_tb.sv`. This testbench drives the top-level `dig_top` instance through the UART path, connects the design to an SRAM behavioral model (`CY7C1049GN_i`), and observes the TFT SPI outputs exactly as a real deployment would use them. In practice, this makes the testbench an end-to-end verification vehicle: a command is injected as UART traffic, decoded by the control plane, executed through the memory subsystem, and finally checked either at the SRAM image or at the TFT serial output.

<p align="center">
<img src="documentation_mkdoc/docs/img/Architecture overview.png">
</p>
<p align="center">
<b>Figure 3.</b> The diagram summarizes the main verification components, including the clock and reset infrastructure, golden reference data, stimulus path, UART bus functional model, SRAM model, and checker logic used to validate the DUT behavior during gate-level simulation.
</p>

More information about the simulation flow, active checkers, and expected data paths can be found in [dig_top_tb_flow_diagram.html](dig_top_tb_flow_diagram.html).


### System-Level Verification

The full-system verification flow is organized around three complementary ideas:

1. **Interface-faithful stimulus**  
   The testbench does not force deep internal signals to mimic system behavior. Instead, it uses the UART Bus Functional Model (`uart_bfm`) and the helper task `uart_write_mem()` to generate valid command packets byte by byte. This ensures that the UART receive path, packet decoder, command arbiter, and downstream blocks are exercised together.

2. **Independent reference data**  
   The testbench builds its own expected data structures before execution begins:
    `tft_init_mem` stores the expected TFT initialization sequence, including command, data, and delay entries.
    `tft_sidebar` stores the expected sidebar stream sent to the TFT.
    `tft_active_area` stores the logical active-screen image used for full-frame display verification.
    `tb_sram` acts as a golden SRAM image. It is initialized from the active-area data and then updated by the testbench's own object-drawing rules before being compared against the DUT-visible SRAM model.

3. **Concurrent checking**  
   Verification is not deferred to a single final comparison. The testbench runs several checker threads in parallel, so protocol violations, timing mismatches, stream ordering errors, and memory corruption are detected close to the cycle where they occur. This is especially important for gate-level simulation, where failures may arise from control sequencing or handshake timing rather than purely functional logic.

### `dig_top_tb.sv` Verification Flow

The top-level testbench starts from a simple but realistic infrastructure:

- a 50 MHz clock generated with `always #10ns clk = !clk;`,
- an active-low reset released after 40 ns,
- an SRAM behavioral model connected to the external-memory pins,
- UART-driven stimulus,
- a serial-output checker for the TFT SPI path,
- and a 30-second timeout thread to convert deadlock into an explicit failure.

After reset, the system verification scenario progresses through the following phases.

#### 1. TFT initialization memory programming

The testbench writes every entry of `tft_init_mem` through UART to the control address used by the screen subsystem. This stage verifies that Lacerta accepts configuration traffic through the host path and correctly stores screen-initialization data before any display action is requested.

#### 2. TFT initialization sequence execution

Once the initialization table is loaded, the testbench configures the SPI clock divider and triggers screen initialization. A dedicated checker thread waits until the TFT control FSM enters its initialization state and then validates each emitted entry:

- for command/data entries, the checker compares `{rom_type, tnsm_data}` against the expected `tft_init_mem` content;
- for delay entries, it measures the elapsed clock cycles and confirms that the observed delay is at least the programmed number of milliseconds multiplied by `CLK_CYCLES_PER_MS`.

This stage verifies more than register programming. It checks that the initialization ROM is consumed in the correct order, that delay entries are honored in time, and that the SPI path receives the exact bytes expected by the TFT controller. After the sequence completes, the testbench asserts that `initialization_done` is high.

#### 3. Sidebar transfer verification

The testbench then prepares a burst write into the shared memory system and streams the sidebar payload through repeated UART writes. After the sidebar-load command is issued, the testbench checks both control behavior and output behavior:

- `sidebar_ongoing` must assert after the command and later deassert when the transfer completes;
- the read buffer must be empty and the read-page generator must be idle at the end of the operation;
- every SPI byte transmitted during the sidebar update must match the expected `tft_sidebar` sequence;
- the `tft_dc` line must indicate command bytes for `CASET`, `RASET`, and `RAMWR`, and data bytes everywhere else.

This verifies the complete path from host programming, to SRAM write buffering, to screen-system memory fetch, to TFT serialization.

#### 4. Color-mapping table programming

The testbench writes randomized RGB565 values into every color-map entry and then reads the corresponding internal table state after a short propagation delay. This confirms that compact logical pixel codes used in the screen image are translated through the correct table entries before being sent to the TFT interface.

#### 5. Full active-screen fetch and display

To verify full-image display behavior, the testbench first loads the active-screen image into SRAM through the UART-controlled write path. It then programs object geometry fields so the screen subsystem fetches the entire active display region and emits it over SPI.

During this phase, the verification logic checks:

- that the TFT control FSM asserts `busy` after the fetch request and later returns to idle;
- that the read buffer is empty and the page generator is no longer busy after completion;
- that the command/window bytes (`CASET`, `RASET`, `RAMWR`, and coordinate bytes) match the expected `tft_active_area` header;
- that each logical pixel in `tft_active_area` is converted into the correct two-byte RGB565 value using the live `color_map` table;
- and that the command/data framing on `tft_dc` remains correct during the whole transfer.

This is an important system-level check because it validates the interaction among stored pixel data, color expansion, frame-window generation, TFT command sequencing, and SPI serialization.

#### 6. Constrained-random drawing-object verification

After the static display paths are verified, the testbench executes `TB_NUM_OBJECTS` randomized drawing scenarios. For each iteration it selects:

- an object type,
- object width and height,
- a value parameter,
- a legal start position (`st_x`, `st_y`),
- and, for mask objects, a legal mask-source base address.

The object type rotates through the drawing modes implemented in the testbench tasks:

- `draw_horizontal_type()`
- `draw_vertical_type()`
- `draw_graph_type()`
- `draw_mask_type()`

Each task programs the DUT through UART exactly as software would: it writes object type, dimensions, start address, screen coordinates, and trigger/value fields. The testbench then waits for the drawing engine completion handshake (`MASK_GEN_PATH.done`) and updates the shadow image `tb_sram` according to an independent expected-behavior model:

- **Horizontal object:** the MSB of each target pixel is set according to the horizontal position relative to `obj_value`.
- **Vertical object:** the MSB of each target pixel is set according to the vertical position relative to `obj_value`.
- **Graph object:** the existing region is shifted and a new column is inserted, modeling graph-history behavior rather than a simple overwrite.
- **Mask object:** the update uses a second memory region as the mask source, stressing source/destination addressing interactions.

After every object operation, `check_sram_consistency()` compares the golden `tb_sram` contents against the actual external SRAM model seen by the DUT. This immediate comparison is valuable because it localizes failures to the most recent object operation instead of postponing diagnosis to the end of the simulation.

#### 7. Microprocessor-enable handoff

At the end of the scenario, the testbench issues the UART command that enables the embedded microprocessor path and verifies that `up_enable` is asserted. This closes the loop on one more top-level control action and ensures the system can hand control to the processor-side flow after host-side configuration.

### Active Checker Structure

The `dig_top_tb.sv` environment contains several simultaneously active verification mechanisms:

- **TFT initialization checker:** validates initialization bytes and delay lengths.
- **Sidebar stream checker:** validates TFT payload bytes and command/data framing.
- **Active-area stream checker:** validates frame-window commands and RGB565-expanded pixel output.
- **SRAM shadow-model checker:** compares the expected image memory against the SRAM model after each draw operation.
- **SPI serialization checker:** samples `tft_mosi` on `tft_sck` edges and confirms that every acknowledged `tnsm_data` byte is serialized MSB first.
- **Control/status assertions:** check flags such as `initialization_done`, `sidebar_ongoing`, `busy`, buffer-empty conditions, and `up_enable`.
- **Timeout protection:** terminates the simulation with a fatal error if the full scenario fails to make progress within 30 seconds.

Together, these checkers provide both transaction-level and bit-level confidence. A failure can therefore be caught as a bad control transition, a wrong memory update, an incorrect TFT byte, or even a serialization mismatch on the SPI output pin.

### Relation to GLS and Documentation Artifacts

This same end-to-end style is especially useful for gate-level simulation because it exercises long control sequences, back-pressure conditions, and external-interface timing without simplifying the problem to a purely combinational comparison. More detailed information about the simulation flow, active checkers, and expected data paths can be found in [dig_top_tb_flow_diagram.html](dig_top_tb_flow_diagram.html). That file documents the actual structure implemented in `dig_top_tb.sv`: UART-driven initialization, sidebar transfer, color-map programming, full active-area fetch, constrained-random object drawing with per-object SRAM comparison, and final processor enable.

Overall, the Lacerta verification methodology combines block-level protocol checking, system-level end-to-end stimulus, reference-model comparison, and gate-level observability. This gives strong confidence that the platform is not only logically correct, but also integration-ready across its communication, memory, drawing, and display subsystems.

### WB Slave to Memory Mapped

The verification plan for the **WB Slave to Memory Mapped** block focuses on protocol correctness, proper memory-side control generation, and legal read/write handshaking.

1. Verify that the Wishbone slave acknowledges only when a valid master request is active.
2. Verify that an active Wishbone request is acknowledged within the maximum allowed number of clock cycles.
3. Verify that `wb_ack_o` is asserted for only one clock cycle per transaction.
4. Verify that address, data, and control signals remain stable while a request is active and has not yet been acknowledged.
5. Verify that `mem_we` is asserted, and `mem_re` is not asserted, during Wishbone write requests.
6. Verify that `mem_re` is asserted, and `mem_we` is not asserted, during Wishbone read requests.
7. Verify that `wb_cyc_i` and `wb_stb_i` are deasserted only after `wb_ack_o`, preventing overlapping requests.
8. Verify that `mem_waddr`, `mem_wdata`, and `mem_wmask` correctly reflect the Wishbone address, data, and byte-select signals during write requests.
9. Verify that `mem_raddr` correctly reflects the Wishbone address during read requests.
10. Verify that `wb_dat_o` returns the same data received from memory when a Wishbone read request completes.
11. Verify that `mem_wr_data_ack` can be asserted only while a Wishbone write transaction is in progress.
12. Verify that `mem_rdy` can be asserted only while a Wishbone read transaction is in progress.

### WB Slave to Read/Write Ports

The verification plan for the **WB Slave to Read/Write Ports** block checks correct Wishbone behavior, proper coordination with the memory-system ports, and correct sequencing of read and write transactions initiated by the microprocessor side.

1. Verify that the Wishbone slave acknowledges only when a valid master request is active.
2. Verify that `wb_ack_o` is asserted for only one clock cycle per transaction.
3. Verify that address, data, and control signals remain stable while a request is active and has not yet been acknowledged.
4. Verify that `wpg_busy` is asserted only for Wishbone write requests and remains clear for read requests.
5. Verify that `wpg_busy` remains asserted until `wpg_ack` is received.
6. Verify that `rpg_busy` is asserted only for Wishbone read requests and remains clear for write requests.
7. Verify that `rpg_busy` remains asserted until `rpg_ack` is received.
8. Verify that `wb_cyc_i` and `wb_stb_i` are deasserted only after `wb_ack_o`, preventing overlapping requests.
9. Verify that `up_en` does not change while a read or write process is in progress.
10. Verify that `up_soft_reset` does not change while a read or write process is in progress.
11. Verify that `wpg_st_addr`, `wpg_burst_length`, and `wr_buff_wdata` are correctly loaded during Wishbone write requests.
12. Verify that `wpg_st_addr`, `wpg_burst_length`, and `wr_buff_wdata` remain stable until `wpg_ack` is asserted.
13. Verify that `rpg_st_addr` and `rpg_burst_length` are correctly loaded during Wishbone read requests.
14. Verify that `rpg_st_addr` and `rpg_burst_length` remain stable until `rpg_ack` is asserted.
15. Verify that `wr_buff_wren` is asserted only during Wishbone write requests and only once per write transaction.
16. Verify that `rd_buff_rden` is asserted only during Wishbone read requests and exactly `NUM_ACCESSES` times per read transaction.
17. Verify that `rpg_ack` can be asserted only while a master read operation is ongoing.
18. Verify that `wpg_ack` can be asserted only while a master write operation is ongoing.
19. Verify that a Wishbone read transaction completes when `rpg_ack` is asserted.
20. Verify that a Wishbone write transaction completes when `wpg_ack` is asserted.
21. Verify that the read buffer is empty whenever no Wishbone read operation is in progress.
22. Verify that the data returned at the end of a Wishbone read matches the data delivered by the memory system.
23. Verify that Wishbone read and write transactions can start only when the microprocessor interface is enabled and not in soft reset.

### Command Arbiter Decoder

The verification plan for the **Command Arbiter Decoder** block checks the validity of drawing commands, busy-state behavior, and the control rules used when enabling or resetting the memory-access path.

1. Verify that when `drw_inc_start` is asserted, the drawing object type is within the valid range and both object width and object height are greater than `MIN_OBJECT_WIDTH_HEIGHT`.
2. Verify that asserting `drw_inc_start` causes `drw_inc_busy` to transition from `0` to `1`.
3. Verify that the drawing data sent to the rendering circuit remains stable while `drw_inc_busy` is asserted.
4. Verify that `drw_inc_busy` is not asserted for longer than `DRW_BUSY_TIMEOUT` clock cycles.
5. Verify that `wb_slave_up_en` is asserted when the UART write command address is `18`.
6. Verify that `wb_slave_up_en` can be deasserted only when no memory-system access transaction is in progress.
7. Verify that `up_soft_reset` can be asserted only when no memory-system access transaction is in progress.

### Mask Generator

The verification plan for the **Mask Generator** block validates correct start/busy sequencing and ensures that internal read/write activity occurs only while the block is actively processing a drawing operation.

1. Verify that asserting `start` causes `busy` to transition from `0` to `1`.
2. Verify that `start` cannot be asserted while `busy` or `done` is already asserted.
3. Verify that when `busy` is deasserted, `rpg_busy` and `wpg_busy` are both low and `rd_buff_empty` is high.
4. Verify that `rd_buff_rden` cannot be asserted when `rd_buff_empty` is high.
5. Verify that `wr_buff_wren` cannot be asserted when `wr_buff_full` is high.
6. Verify that `rpg_busy`, `wpg_busy`, `rpg_ack`, `wpg_ack`, `wr_buff_full`, `rd_buff_rden`, and `wr_buff_wren` can be asserted only while `busy` is high.


--------------------- OLD README ------------------------

The goal of Lacerta is to provide a low-cost, fully open-source reference architecture for embedded human–machine interfaces (HMI). By combining configurable hardware graphics generation with flexible input interfaces, Lacerta enables the rapid development of customizable dashboards and monitoring systems for industrial, commercial, and edge-IoT applications.

<p align="center">
<img src="documentation_mkdoc/docs/img/Flow_interface.drawio.svg">
</p>
<p align="center">
<b>Figure 4.</b> Lacerta interface creation workflow. A graphical editor is used to design custom interface layouts, which are translated into configuration data interpreted by the Lacerta hardware engine to generate the graphical display.
</p>

<p align="center">
<img src="documentation_mkdoc/docs/img/lacerta_blockd2-caravel.drawio.svg">
</p>
<p align="center">
<b>Figure 5.</b> Block diagram of the Lacerta ASIC inside the Caravel environment. The figure shows how a host computer or the embedded Caravel RISC-V processor sends commands through UART and Wishbone interfaces to the command arbiter, rendering logic, and memory subsystem; the updated frame data is then read by the VGA controller to drive the screen.
</p>

## Open and Reproducible Architecture

Lacerta is designed as a **fully open-source reference architecture**. The project includes all required design artifacts to reproduce the system, including:

- [Documentation](https://baungarten-cinvestav.github.io/lacerta/)
- [RTL source code for the ASIC implementation](https://github.com/Baungarten-CINVESTAV/lacerta/tree/main/verilog/rtl)
- [Librelane physical design flow integration](https://github.com/Baungarten-CINVESTAV/lacerta/tree/main/openlane)  
<!--- [Verification testbenches]()  -->
- [PCB design files](https://github.com/Baungarten-CINVESTAV/lacerta/tree/main/PCB)
- [Firmware examples](https://github.com/chipfoundry/caravel_board)  
- [Interface design tools](https://github.com/Baungarten-CINVESTAV/lacerta/tree/main/Interface_Design_Software)

### Lacerta Interface Design Software — GUI Notes

Important:
- The prebuilt GUI in this repository is currently distributed as a Windows executable package and can only be run on **Windows**.
- Before running the GUI, you must extract the files located in `Interface_Design_Software/exe_file_GUI` (the RAR parts). Ensure all parts are in the same directory and extract them with a tool such as 7-Zip or WinRAR.

Quick steps
1. Copy the folder [Interface_Design_Software/exe_file_GUI](https://github.com/Baungarten-CINVESTAV/lacerta/tree/main/Interface_Design_Software/exe_file_GUI) to a Windows machine (or access it from Windows).
2. Extract/unpack all archive parts (e.g. LacertaHMIDesigner.part1.rar, part2, part3) into a single directory.
3. Run the extracted installer or executable on Windows.

