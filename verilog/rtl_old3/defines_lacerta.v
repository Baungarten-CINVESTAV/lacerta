// Timing parameters
parameter CLOCK_FREQUENCY = 50_000_000; // 50 MHz
parameter MAIN_MEM_ADDR_WIDTH = 17;
parameter MAIN_MEM_DATA_WIDTH = 8;
parameter MAIN_MEM_DATA_BYTES = (MAIN_MEM_DATA_WIDTH/8) > 1 ? (MAIN_MEM_DATA_WIDTH/8) : 1;

// Communication protocol parameters (uart/wishbone)
parameter UART_BYTES_DATA = 4;
parameter UART_BYTES_ADDRESS = 1;
parameter WB_ADDR_WIDTH = 32;
parameter WB_DATA_WIDTH = 32;

// screen configuration
parameter COLOR_MAP_NUM = 16;
parameter SCREEN_WIDTH = 320;
parameter SCREEN_HEIGHT = 240;
parameter ACTIVE_SCREEN_WIDTH = 270; // as we only have 16 pins of addresses, we can't use the whole SCREEN_WIDTH for drawing
parameter SCREEN_SIZE = SCREEN_WIDTH*SCREEN_HEIGHT;
parameter SCREEN_INIT_MEM_SIZE = 64;
parameter SIDEBAR_WIDTH = SCREEN_WIDTH - ACTIVE_SCREEN_WIDTH;
parameter SIDEBAR_HEIGHT = SCREEN_HEIGHT;
parameter SIDEBAR_SIZE = SIDEBAR_WIDTH*SIDEBAR_HEIGHT;
parameter SIDEBAR_STADDR = 0;

// Memory system parameters
parameter NUM_READ_BUFFERS = 4;
parameter NUM_ELEMENTS_READ_BUFFERS = 16;
parameter NUM_WRITE_BUFFERS = 3;
parameter NUM_ELEMENTS_WRITE_BUFFERS = 16;
parameter READ_BUFFERS_DATA_WIDTH = MAIN_MEM_DATA_WIDTH;
parameter WRITE_BUFFERS_DATA_WIDTH = MAIN_MEM_DATA_WIDTH;

localparam BOOLEAN_TYPE = 0;
localparam HORIZONTAL_INCREMENTAL_TYPE = 1;
localparam VERTICAL_INCREMENTAL_TYPE = 2;
localparam GRAPH_TYPE = 3;
localparam MASK_TYPE = 4; // like 7 segment displays
localparam MAXIMUM_INCREMENTAL_WIDTH = 500;
localparam MAXIMUM_INCREMENTAL_HEIGHT = 500;
localparam MAXIMUM_INCREMENTAL_WIDTH_BITS = $clog2(MAXIMUM_INCREMENTAL_WIDTH);
localparam MAXIMUM_INCREMENTAL_HEIGHT_BITS = $clog2(MAXIMUM_INCREMENTAL_HEIGHT);

parameter IMAGE_BASE_ADDRESS = 32'h0000_0000;
parameter MASKS_BASE_ADDRESS = 32'h0000_FD20; // ACTIVE_SCREEN_WIDTH x SCREEN_HEIGHT == 64,800
parameter UP_INSTR_BASE_ADDRESS = 32'h0001_0000; // 2^ADDRESS_WIDTH - for fpga validation only, as in silicon, we are using caravel rv, that doesn't read the instructions from memory system, but from flash