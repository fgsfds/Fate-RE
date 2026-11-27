/* Load and release a mapped digital driver image. */
/* Check both parts of the far address in the original word/dword registers. */
extern void load_selector(const void *);
#pragma aux load_selector = "mov ax,[eax+4]" parm [eax] modify exact [eax];
extern unsigned short saved_selector(void);
#pragma aux saved_selector = "" value [ax] modify exact [];
extern unsigned long load_offset(const void *);
#pragma aux load_offset = "mov edx,[ecx]" parm [ecx] value [edx] modify exact [edx];
typedef union {
    void __far *pointer;
    struct {
        unsigned long offset;
        unsigned short selector, padding;
    } address;
} DriverFarAddress;

typedef struct {
    char reserved[0xd8];
    DriverFarAddress data, code;
    unsigned long image_size, linear_base;
    char reservedf0[0xc];
    unsigned long memory_handle;
} DriverImage;

extern DriverImage *audio_driver_slots[];
extern char audio_driver_path[], driver_file_path[], driver_filename[];
extern char driver_file_header[], driver_entry_header[];
extern unsigned driver_entry_count, driver_entry_id, driver_entry_size;
extern unsigned char driver_entry_flags;

extern char *driver_strcpy(char *, const char *);
#pragma aux driver_strcpy "strcpy_" parm [eax] [edx] modify exact [eax edx];
extern char *driver_strcat(char *, const char *);
#pragma aux driver_strcat "strcat_" parm [eax] [edx] modify exact [eax edx];
extern int driver_open(const char *, int);
#pragma aux driver_open "open_" parm caller [] modify exact [eax];
extern int driver_read(int, void *, unsigned);
#pragma aux driver_read "read_" parm [eax] [edx] [ebx] modify exact [eax ebx edx];
extern long driver_seek(int, long, int);
#pragma aux driver_seek "lseek_" parm [eax] [edx] [ebx] modify exact [eax ebx edx];
extern void driver_close(int);
#pragma aux driver_close "close_" parm [eax] modify exact [eax];
extern void __far *allocate_driver_memory(unsigned, unsigned long *, unsigned long *);
#pragma aux allocate_driver_memory parm caller [] modify exact [eax edx];
extern void __far *get_driver_alias(unsigned long, unsigned);
#pragma aux get_driver_alias parm caller [] modify exact [eax edx];
extern int lock_memory_region(unsigned long, unsigned);
#pragma aux lock_memory_region parm caller [] modify exact [eax];
extern int unlock_memory_region(unsigned long, unsigned);
#pragma aux unlock_memory_region parm caller [] modify exact [eax];
extern void release_driver_memory(unsigned long, unsigned, unsigned long);
#pragma aux release_driver_memory parm caller [] modify exact [eax];
extern int read_driver_image(int, void __far *, unsigned, unsigned *);
#pragma aux read_driver_image parm routine [eax] [ebx ecx] [edx] [] modify exact [eax ebx ecx edx];

/* GS is listed to suppress Watcom's unused save in the unoptimized frame. */
int load_audio_driver_image(unsigned, unsigned, DriverFarAddress *, DriverFarAddress *,
                            unsigned long *, unsigned char *, unsigned long *);
#pragma aux load_audio_driver_image modify exact [eax ebx ecx edx gs];
int load_audio_driver_image(unsigned id, unsigned slot, DriverFarAddress *code, DriverFarAddress *data,
                            unsigned long *handle, unsigned char *image_size_byte, unsigned long *linear)
{
    int file;
    unsigned index;
    int found;
    unsigned image_state;
    index = 0;
    found = 0;
    if (slot > 5)
        return 10;
    if (id < 0xe000 || id > 0xe200)
        return 6;

    driver_strcpy(driver_file_path, audio_driver_path);
    driver_strcat(driver_file_path, driver_filename);
    file = driver_open(driver_file_path, 0x200);
    if (file == -1)
        return 15;
    driver_read(file, driver_file_header, 0x2c);
    while (index <= driver_entry_count && !found) {
        driver_read(file, driver_entry_header, 0x30);
        if (driver_entry_id == id && (driver_entry_flags & 0x80)) {
            found = 1;
            data->pointer = allocate_driver_memory(driver_entry_size, handle, linear);
            load_selector(data);
            if (!load_offset(data)) {
                if (!saved_selector())
                    return 5;
            }
            code->pointer = get_driver_alias(data->address.offset, data->address.selector);
            if (lock_memory_region(*linear, driver_entry_size))
                return 5;
            read_driver_image(file, data->pointer, driver_entry_size, &image_state);
            *image_size_byte = (unsigned char)driver_entry_size;
        } else {
            driver_seek(file, driver_entry_size, 1);
        }
        ++index;
    }
    driver_close(file);
    return 0;
}

int unload_audio_driver_image(unsigned);
#pragma aux unload_audio_driver_image parm [eax] modify exact [eax gs];
int unload_audio_driver_image(unsigned slot)
{
    DriverImage *driver;
    if (slot > 5)
        return 10;
    driver = audio_driver_slots[slot];
    if (!driver)
        return 10;
    if (unlock_memory_region(driver->linear_base, driver->image_size))
        return 5;
    release_driver_memory(driver->data.address.offset, driver->data.address.selector, driver->memory_handle);
    release_driver_memory(driver->code.address.offset, driver->code.address.selector, driver->memory_handle);
    return 0;
}
