/* HMI callback scheduling uses 16.16 PIT tick accumulators. */
#define PIT_CLOCK 0x1234dcUL
#define TIMER_SLOTS 16
#define BIOS_RATE 0xff00UL
#define BIOS_DIVISOR 0xffffUL
#define ONE_TICK 0x10000UL
#define BIOS_RATE_SCALED 0x123333UL

typedef void TimerCallback(void);
#pragma aux TimerCallback modify exact [eax];

typedef union {
    unsigned long value;
    struct { unsigned short fraction, ticks; } words;
} TickAccumulator;

typedef struct {
    unsigned char value;
    unsigned char reserved[3];
} TimerContext;

extern unsigned char pit_programming_enabled, use_dpmi_vector, timer_flags;
extern unsigned long pit_divisor;
extern TimerCallback *timer_callbacks[], *default_timer_slot;
extern unsigned long timer_frequencies[], timer_increments[], default_timer_frequency, default_timer_increment;
extern TickAccumulator timer_accumulators[];
extern TimerContext timer_contexts[];
extern unsigned long current_timer_context;

extern void program_pit(unsigned long);
#pragma aux program_pit parm caller [] modify exact [eax];
extern void install_timer_vector(unsigned long, void (*)(void));
#pragma aux install_timer_vector parm caller [] modify exact [eax];
extern void mask_timer_irq(void);
#pragma aux mask_timer_irq modify exact [eax];
extern void unmask_timer_irq(void);
#pragma aux unmask_timer_irq modify exact [eax];
extern void restore_timer_vector(void);
#pragma aux restore_timer_vector modify exact [eax];
extern void chain_original_timer(void);
#pragma aux chain_original_timer modify exact [eax];

int timer_set_divisor(unsigned long);
#pragma aux timer_set_divisor parm [eax] modify exact [eax gs];
void timer_dispatch_callbacks(void);
#pragma aux timer_dispatch_callbacks modify exact [eax gs];
void default_timer_callback(void);
#pragma aux default_timer_callback modify exact [eax gs];

void timer_module_noop(void);
#pragma aux timer_module_noop modify exact [eax gs];
void timer_module_noop(void)
{
}

int timer_initialize(unsigned long, unsigned);
#pragma aux timer_initialize parm [eax] [edx] modify exact [eax edx gs];
int timer_initialize(unsigned long frequency, unsigned flags)
{
    /* Retain the original stack slot in Watcom's frame. */
    volatile int reserved;

    if (flags & 2)
        use_dpmi_vector = 1;
    else
        use_dpmi_vector = 0;

    if (!(flags & 1)) {
        pit_programming_enabled = 1;
        timer_flags |= 1;
        mask_timer_irq();
        install_timer_vector(BIOS_DIVISOR, timer_dispatch_callbacks);
        unmask_timer_irq();
    } else {
        timer_flags &= ~1;
    }
    if (frequency && !(flags & 1)) {
        if (frequency == BIOS_RATE) {
            timer_set_divisor(BIOS_DIVISOR);
            default_timer_frequency = BIOS_RATE;
        } else {
            timer_set_divisor(PIT_CLOCK / frequency);
            default_timer_frequency = frequency;
        }
        default_timer_slot = default_timer_callback;
        default_timer_increment = ONE_TICK;
    } else {
        pit_divisor = BIOS_DIVISOR;
    }
    return 0;
}

int timer_shutdown(unsigned);
#pragma aux timer_shutdown parm [eax] modify exact [eax gs];
int timer_shutdown(unsigned unused)
{
    if (timer_flags & 1) {
        mask_timer_irq();
        restore_timer_vector();
        unmask_timer_irq();
    }
    return 0;
}

/* The three updating routines expand the same fixed-point calculation inline. */
#define SET_INCREMENT(index) \
    if (timer_frequencies[index] == BIOS_RATE) { \
        if (pit_divisor == BIOS_DIVISOR) \
            timer_increments[index] = ONE_TICK; \
        else \
            timer_increments[index] = BIOS_RATE_SCALED / (PIT_CLOCK / pit_divisor); \
    } else { \
        timer_increments[index] = (timer_frequencies[index] << 16) / (PIT_CLOCK / pit_divisor); \
    }

int timer_register_callback(unsigned long, TimerCallback *, unsigned *);
#pragma aux timer_register_callback parm [eax] [edx] [ebx] modify exact [eax ebx edx gs];
int timer_register_callback(unsigned long frequency, TimerCallback *callback, unsigned *slot)
{
    unsigned index, selected;
    unsigned long ratio = 0;
    unsigned long scaled;

    for (index = 0; index < TIMER_SLOTS; ++index) {
        if (!timer_callbacks[index])
            break;
    }
    if (index >= TIMER_SLOTS)
        return 11;
    if (timer_flags & 1)
        mask_timer_irq();
    selected = index;
    timer_callbacks[index] = callback;
    timer_frequencies[index] = frequency;
    if ((PIT_CLOCK / frequency) < pit_divisor) {
        timer_set_divisor(PIT_CLOCK / frequency);
        ratio = (pit_divisor << 16) / (PIT_CLOCK / frequency);
    }
    for (index = 0; index < TIMER_SLOTS; ++index) {
        if (timer_callbacks[index]) {
            SET_INCREMENT(index)
            if (ratio) {
                scaled = (timer_accumulators[index].value * (ratio & 0xffff)) >> 16;
                scaled += (timer_accumulators[index].value * (ratio >> 16)) >> 16;
                timer_accumulators[index].value = scaled;
            }
        }
    }
    if (timer_flags & 1)
        unmask_timer_irq();
    *slot = selected;
    return 0;
}

int timer_set_frequency(unsigned, unsigned long);
#pragma aux timer_set_frequency parm [eax] [edx] modify exact [eax edx gs];
int timer_set_frequency(unsigned slot, unsigned long frequency)
{
    unsigned index;
    if (slot >= TIMER_SLOTS)
        return 10;
    if (timer_callbacks[slot]) {
        if (timer_flags & 1)
            mask_timer_irq();
        timer_frequencies[slot] = frequency;
        if ((PIT_CLOCK / frequency) < pit_divisor)
            timer_set_divisor(PIT_CLOCK / frequency);
        for (index = 0; index < TIMER_SLOTS; ++index) {
            if (timer_callbacks[index]) {
                SET_INCREMENT(index)
                timer_accumulators[index].value = 0;
            }
        }
        if (timer_flags & 1)
            unmask_timer_irq();
    } else {
        return 10;
    }
    return 0;
}

int timer_remove_callback(unsigned);
#pragma aux timer_remove_callback parm [eax] modify exact [eax gs];
int timer_remove_callback(unsigned slot)
{
    unsigned index;
    unsigned long max_frequency = 0;
    timer_callbacks[slot] = 0;
    for (index = 0; index < TIMER_SLOTS; ++index) {
        if (timer_callbacks[index]) {
            if (timer_frequencies[index] > max_frequency && timer_frequencies[index] != BIOS_RATE)
                max_frequency = timer_frequencies[index];
        }
    }
    if (max_frequency)
        timer_set_divisor(PIT_CLOCK / max_frequency);
    else
        timer_set_divisor(BIOS_DIVISOR);
    if (timer_flags & 1)
        mask_timer_irq();
    for (index = 0; index < TIMER_SLOTS; ++index) {
        if (timer_callbacks[index]) {
            SET_INCREMENT(index)
            timer_accumulators[index].value = 0;
        }
    }
    if (timer_flags & 1)
        unmask_timer_irq();
    return 0;
}

unsigned long timer_get_frequency(unsigned);
#pragma aux timer_get_frequency parm [eax] modify exact [eax gs];
unsigned long timer_get_frequency(unsigned slot)
{
    return timer_frequencies[slot];
}

int timer_set_divisor(unsigned long divisor)
{
    pit_divisor = divisor;
    program_pit(divisor);
    return 0;
}

void timer_dispatch_callbacks(void)
{
    unsigned index;
    for (index = 0; index < TIMER_SLOTS; ++index) {
        if (timer_callbacks[index]) {
            timer_accumulators[index].value += timer_increments[index];
            if (timer_accumulators[index].words.ticks & 1) {
                /* Consume the elapsed tick and keep the fractional carry. */
                timer_accumulators[index].words.ticks = 0;
                if (timer_contexts[index].value != (unsigned char)0xff)
                    current_timer_context = timer_contexts[index].value;
                timer_callbacks[index]();
            }
        }
    }
}

void default_timer_callback(void)
{
    chain_original_timer();
}

void timer_tail_noop(void);
#pragma aux timer_tail_noop modify exact [eax gs];
void timer_tail_noop(void)
{
}
