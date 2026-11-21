/* Open an HMI driver and initialize its DMA ring and mixer workspace. */
typedef union {
    void __far *pointer;
    struct {
        unsigned long offset;
        unsigned short selector, padding;
    } address;
} DriverFarAddress;

typedef struct {
    unsigned char flags;
    char reserved01[3];
    unsigned long rate, channels, bits, pan, minimum_block, dma_count_port;
    unsigned long next_cursor, cursor, samples_due;
    unsigned char *write_cursor;
    unsigned long mix_block;
    void *queue;
    DriverFarAddress position;
    unsigned char *ring, *ring_end;
    unsigned long ring_size;
    unsigned char *workspace, *workspace_end;
    unsigned long workspace_size;
    long active_samples;
    void *samples;
    unsigned long io_base, irq, dma, extra_dma;
    char interface_prefix[0x24];
    unsigned long format_bits, format_stereo;
    char interface_middle[0x11];
    unsigned char interface_flags;
    char interface_end[0x2e];
    DriverFarAddress data, code;
    unsigned char image_size;
    char image_size_padding[3];
    unsigned long image_base, buffer_base;
    DriverFarAddress dma_buffer;
    unsigned long image_handle, physical, id;
    void (*service)(void);
} Driver;

extern Driver *audio_driver_slots[];
extern unsigned long dma_count_ports[];
extern void (*audio_driver_services[])(void);

extern int load_audio_driver_image(unsigned, unsigned, DriverFarAddress *, DriverFarAddress *,
                                   unsigned long *, unsigned char *, unsigned long *);
#pragma aux load_audio_driver_image modify exact [eax ebx ecx edx];
extern void *allocate_driver_workspace(unsigned long);
#pragma aux allocate_driver_workspace parm [eax] modify exact [eax];
extern void *clear_driver_memory(void *, int, unsigned);
#pragma aux clear_driver_memory "memset_" parm [eax] [edx] [ebx] modify exact [eax ebx edx];
extern int query_driver_interface(unsigned, void *);
#pragma aux query_driver_interface parm [eax] [edx] modify exact [eax edx];
extern unsigned char *allocate_audio_buffer(unsigned long, unsigned long *, unsigned long *, DriverFarAddress *);
#pragma aux allocate_audio_buffer modify exact [eax ebx ecx edx];
extern int unload_audio_driver_image(unsigned);
#pragma aux unload_audio_driver_image parm [eax] modify exact [eax];

extern void __far *driver_command_11(unsigned long, unsigned, unsigned long, unsigned);
#pragma aux driver_command_11 parm caller [] modify exact [eax edx];
extern void windows_driver_interrupt(unsigned long);
#pragma aux windows_driver_interrupt parm caller [] modify exact [eax];
extern void driver_configure_secondary(unsigned long, unsigned, unsigned long, unsigned,
                                      unsigned long, unsigned long, unsigned long,
                                      unsigned long, unsigned long, unsigned long);
#pragma aux driver_configure_secondary parm caller [] modify exact [eax];
extern void driver_secondary_command_3(unsigned long, unsigned, unsigned long, unsigned);
#pragma aux driver_secondary_command_3 parm caller [] modify exact [eax];
extern void driver_secondary_command_2(unsigned long, unsigned, unsigned long, unsigned, unsigned long);
#pragma aux driver_secondary_command_2 parm caller [] modify exact [eax];
extern void driver_secondary_command_4(unsigned long, unsigned, unsigned long, unsigned, unsigned long, unsigned long);
#pragma aux driver_secondary_command_4 parm caller [] modify exact [eax];

#define DRIVER_ADDRESS(driver) \
    (driver)->code.address.offset, (driver)->code.address.selector, \
    (driver)->data.address.offset, (driver)->data.address.selector

/* The historical null test loads the ring into EAX before testing it. */
extern unsigned char *load_ring(Driver *);
#pragma aux load_ring = "mov eax,[eax+3ch]" parm [eax] value [eax] modify exact [eax];

int audio_driver_init(Driver *, unsigned *);
#pragma aux audio_driver_init parm [eax] [edx] modify exact [eax edx gs];
int audio_driver_init(Driver *driver, unsigned *out_slot)
{
    unsigned slot, i;
    int status;

    for (slot = 0; slot < 5; ++slot) {
        if (!audio_driver_slots[slot])
            break;
    }
    /* Preserve the historical slot-exhaustion check. */
    if (slot == 6)
        return 11;
    audio_driver_slots[slot] = driver;
    if (!driver->data.address.offset) {
        if (!driver->data.address.selector) {
            status = load_audio_driver_image(driver->id, slot, &driver->code, &driver->data,
                                             &driver->image_handle, &driver->image_size, &driver->image_base);
            if (status)
                return status;
            driver->samples = allocate_driver_workspace(0x1e00);
            driver->workspace = allocate_driver_workspace(0x4000);
            driver->flags |= 2;
        }
    }

    clear_driver_memory(driver->samples, 0, 0x1e00);
    status = query_driver_interface(slot, driver->interface_prefix);
    if (status)
        return status;

    if (!driver->ring) {
        driver->flags |= 4;
        driver->ring = allocate_audio_buffer(driver->ring_size, &driver->buffer_base,
                                             &driver->physical, &driver->dma_buffer);
        if (!load_ring(driver)) {
            unload_audio_driver_image(slot);
            return 5;
        }

        if (driver->format_bits == 8) {
            if (driver->interface_flags & 0x80) {
                for (i = 0; i < driver->ring_size; ++i)
                    driver->ring[i] = 0;
            } else {
                for (i = 0; i < driver->ring_size; ++i)
                    driver->ring[i] = 0x80;
            }
        } else {
            for (i = 0; i < driver->ring_size; ++i)
                driver->ring[i] = 0;
        }
    }

    driver->ring_end = driver->ring + driver->ring_size;
    driver->dma_count_port = dma_count_ports[driver->dma];
    driver->write_cursor = driver->ring;
    driver->workspace_end = driver->workspace + 0x4000;
    driver->workspace_size = 0x4000;
    driver->queue = 0;
    driver->active_samples = -1;
    driver->mix_block = 0x400;
    driver->minimum_block = 0x20;
    driver->bits = driver->format_bits;
    driver->channels = driver->format_stereo + 1;
    driver->pan = 0x8000;
    driver->service = audio_driver_services[slot];
    driver->next_cursor = 0;
    driver->cursor = 0;
    driver->samples_due = 0;

    if (driver->interface_flags & 2)
        driver->position.pointer = driver_command_11(DRIVER_ADDRESS(driver));
    windows_driver_interrupt(driver->dma);
    driver_configure_secondary(DRIVER_ADDRESS(driver), driver->io_base, driver->irq,
                               driver->dma, driver->extra_dma, driver->extra_dma, driver->extra_dma);
    driver_secondary_command_3(DRIVER_ADDRESS(driver));
    driver_secondary_command_2(DRIVER_ADDRESS(driver), driver->rate);
    driver_secondary_command_4(DRIVER_ADDRESS(driver), driver->buffer_base, driver->ring_size);
    driver->flags |= 1;
    *out_slot = slot;
    return 0;
}
