/* Allocate audio buffers and release the resources owned by a digital driver. */
typedef union {
    void __far *pointer;
    struct {
        unsigned long offset;
        unsigned short selector;
    } address;
} AudioFarBuffer;
extern int query_extender(void);
#pragma aux query_extender modify exact [eax];
extern int allocate_dpmi_audio_buffer(AudioFarBuffer *, unsigned long *, unsigned long *);
#pragma aux allocate_dpmi_audio_buffer parm [eax] [edx] [ebx] modify exact [eax ebx edx];
extern void allocate_dos_buffer(unsigned, unsigned long *, unsigned long *);
#pragma aux allocate_dos_buffer parm caller [] modify exact [eax];
extern int lock_memory_region(unsigned long, unsigned long);
#pragma aux lock_memory_region parm caller [] modify exact [eax];
typedef struct {
    unsigned char flags;
    char reserved01[0x30-1];
    void *queue;
    char reserved34[0x48-0x34];
    void *workspace;
    char reserved4c[4];
    unsigned long workspace_size;
    char reserved54[4];
    void *samples;
    char reserved5c[8];
    unsigned long control;
    char reserved68[0xd8-0x68];
    AudioFarBuffer data;
    unsigned short data_padding;
    AudioFarBuffer code;
    unsigned short code_padding;
    char reservede8[8];
    unsigned long release_cookie;
    AudioFarBuffer buffer;
    char reservedfa[6];
    unsigned long physical;
} AudioDriverBuffers;
extern AudioDriverBuffers *audio_driver_slots[];
extern int driver_command_5(unsigned long, unsigned, unsigned long, unsigned);
#pragma aux driver_command_5 parm caller [] modify exact [eax];
extern int driver_secondary_command_1(unsigned long, unsigned, unsigned long, unsigned);
#pragma aux driver_secondary_command_1 parm caller [] modify exact [eax];
extern void windows_driver_interrupt_stop(long);
#pragma aux windows_driver_interrupt_stop parm caller [] modify exact [eax];
extern void release_dpmi_audio_buffer(unsigned, unsigned long, unsigned long);
#pragma aux release_dpmi_audio_buffer parm [eax] [edx] [ebx] modify exact [eax ebx edx];
extern void release_dos_buffer(unsigned);
#pragma aux release_dos_buffer parm caller [] modify exact [eax];
extern int unload_audio_driver_image(unsigned);
#pragma aux unload_audio_driver_image parm [eax] modify exact [eax];
extern void release_driver_workspace(void *, unsigned long);
#pragma aux release_driver_workspace parm [eax] [edx] modify exact [eax edx];

/* Preserve the selector extraction code and the driver's split-register ABI. */
extern unsigned legacy_buffer_selector(void __far *);
#pragma aux legacy_buffer_selector = "movzx eax,dx" parm [dx eax] value [eax] modify exact [eax edx];
/* The mapped-buffer routine receives its two dword arguments in EDX and EBX. */
extern void release_mapped_buffer(void __far *, unsigned long, unsigned long);
#pragma aux release_mapped_buffer = "movzx eax,dx" "mov ebx,ecx" "mov edx,esi" "call release_dpmi_audio_buffer" parm [dx eax] [esi] [ecx] modify exact [eax ebx edx];

/* GS is listed to suppress Watcom's unused save in the unoptimized frame. */
int audio_driver_shutdown(unsigned, int, int);
#pragma aux audio_driver_shutdown modify exact [eax ebx edx gs];
int audio_driver_shutdown(unsigned slot, int release_buffer, int release_image)
{
    AudioDriverBuffers *driver = audio_driver_slots[slot];
    if (!driver)
        return 10;
    if (!(driver->flags & 2))
        return 1;
    driver->queue = 0;
    driver_command_5(driver->code.address.offset, driver->code.address.selector,
                     driver->data.address.offset, driver->data.address.selector);
    driver_secondary_command_1(driver->code.address.offset, driver->code.address.selector,
                                driver->data.address.offset, driver->data.address.selector);
    windows_driver_interrupt_stop(driver->control);
    if ((driver->flags & 4) && release_buffer) {
        driver->flags &= ~4;
        if ((query_extender() & 0xff) == 3) {
            release_mapped_buffer(driver->buffer.pointer,
                                  driver->physical, driver->release_cookie);
        } else {
            release_dos_buffer(legacy_buffer_selector(driver->buffer.pointer));
            driver->flags &= ~4;
        }
    }
    if ((driver->flags & 2) && release_image) {
        unload_audio_driver_image(slot);
        driver->data.pointer = 0;
        driver->code.pointer = 0;
        release_driver_workspace(driver->workspace, driver->workspace_size);
        release_driver_workspace(driver->samples, 0x1e00);
        driver->flags &= ~2;
    }
    audio_driver_slots[slot] = 0;
    driver->flags &= ~1;
    return 0;
}

unsigned long allocate_audio_buffer(unsigned long, unsigned long *, unsigned long *, AudioFarBuffer *);
#pragma aux allocate_audio_buffer modify exact [eax ebx ecx edx gs];
unsigned long allocate_audio_buffer(unsigned long bytes, unsigned long *base,
                                    unsigned long *physical, AudioFarBuffer *buffer)
{
    unsigned long selector;

    if ((query_extender() & 0xff) == 3) {
        if (allocate_dpmi_audio_buffer(buffer, physical, base) != 0)
            return 0;
        lock_memory_region(buffer->address.offset, bytes);
        return buffer->address.offset;
    } else {
        allocate_dos_buffer((bytes >> 4) + 4, base, &selector);
        while ((*base & 0xffff) > 0xffff - bytes)
            allocate_dos_buffer((bytes >> 4) + 4, base, &selector);
        buffer->pointer = (void __far *)((__segment)selector :> (void *)0);
        return *base;
    }
}
