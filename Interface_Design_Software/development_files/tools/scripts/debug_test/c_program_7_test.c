#include <stdint.h>

#define REG_VALUE      0x8000002C
#define REG_TYPE       0x80000030
#define REG_WIDTH      0x80000034
#define REG_HEIGHT     0x80000038
#define REG_ADDR       0x8000003C
#define REG_MASK_ADDR  0x80000040

static inline uint32_t read_mem(uint32_t addr)
{
    volatile uint32_t *ptr = (volatile uint32_t *)addr;
    return *ptr;
}

static inline void write_mem(uint32_t addr, uint32_t val)
{
    volatile uint32_t *ptr = (volatile uint32_t *)addr;
    *ptr = val;
}

/* delay implemented in delay.S */
void delay(void);

/* ------------------------------------------------------------
 * Generic object refresh
 * ------------------------------------------------------------ */
static void refresh_object(uint32_t type,
                           uint32_t value,
                           uint32_t width,
                           uint32_t height,
                           uint32_t start_addr,
                           uint32_t mask_addr)
{
    write_mem(REG_TYPE, type);
    write_mem(REG_WIDTH, width);
    write_mem(REG_HEIGHT, height);
    write_mem(REG_ADDR, start_addr);
    write_mem(REG_MASK_ADDR, mask_addr);
    write_mem(REG_VALUE, value);
}

/* ------------------------------------------------------------
 * Digit (mask depends on value)
 * ------------------------------------------------------------ */
static void refresh_digit(uint32_t value,
                          uint32_t width,
                          uint32_t height,
                          uint32_t start_addr,
                          uint32_t mask_base)
{
    uint32_t mask_addr = mask_base + value * width * height;

    refresh_object(
        4,              /* type */
        0,              /* value not used for digit */
        width,
        height,
        start_addr,
        mask_addr
    );
}

/* ------------------------------------------------------------
 * Graph
 * ------------------------------------------------------------ */
static void refresh_graph(uint32_t value,
                          uint32_t width,
                          uint32_t height,
                          uint32_t start_addr)
{
    refresh_object(
        3,
        value,
        width,
        height,
        start_addr,
        0xFFFFFFFF
    );
}

/* ------------------------------------------------------------
 * Vertical
 * ------------------------------------------------------------ */
static void refresh_vertical(uint32_t value,
                             uint32_t width,
                             uint32_t height,
                             uint32_t start_addr)
{
    refresh_object(
        2,
        value,
        width,
        height,
        start_addr,
        0xFFFFFFFF
    );
}

/* ------------------------------------------------------------
 * Horizontal
 * ------------------------------------------------------------ */
static void refresh_horizontal(uint32_t value,
                               uint32_t width,
                               uint32_t height,
                               uint32_t start_addr)
{
    refresh_object(
        1,
        value,
        width,
        height,
        start_addr,
        0xFFFFFFFF
    );
}

/* ------------------------------------------------------------
 * Main
 * ------------------------------------------------------------ */
int main(void)
{
    uint32_t counter = 0;
    uint32_t counter_7seg = 0;

    while (1) {

        if (counter > 100)
            counter = 0;

        if (counter_7seg > 9)
            counter_7seg = 0;

        // INSERT ELEMENTS HERE

        // END OF ELEMENTS
 
        counter += 10;
        counter_7seg += 1;
    }

    return 0;
}