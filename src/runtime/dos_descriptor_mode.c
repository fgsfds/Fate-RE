typedef union {
    unsigned long value;
    unsigned char bytes[4];
} DescriptorMode;

extern unsigned descriptor_count;
extern DescriptorMode *descriptor_modes;
extern int isatty(int);
#pragma aux isatty modify exact [eax];

/* Preserve the original registers for mode table addressing and the flag byte. */
extern int keep_mode_offset(int);
#pragma aux keep_mode_offset = parm [ebx] value [ebx] modify exact [];
extern unsigned char keep_mode_flags(unsigned char);
#pragma aux keep_mode_flags = parm [cl] value [cl] modify exact [];
extern unsigned char keep_detected_flags(unsigned char);
#pragma aux keep_detected_flags = parm [ch] value [ch] modify exact [];
extern int keep_descriptor_index(int);
#pragma aux keep_descriptor_index = parm [edx] value [edx] modify exact [];
extern DescriptorMode *keep_mode_table(DescriptorMode *);
#pragma aux keep_mode_table = parm [eax] value [eax] modify exact [];
extern unsigned long keep_new_mode(unsigned long);
#pragma aux keep_new_mode = parm [ebx] value [ebx] modify exact [];

unsigned long get_io_mode(int descriptor)
{
    if ((unsigned)descriptor >= descriptor_count)
        return 0;
    if (descriptor <= 5) {
        int offset = keep_mode_offset(descriptor);
        DescriptorMode *table = keep_mode_table(descriptor_modes);
        DescriptorMode *mode;
        unsigned char flags;
        offset = keep_mode_offset(offset * sizeof(DescriptorMode));
        mode = (DescriptorMode *)((unsigned char *)table + offset);
        flags = keep_mode_flags(mode->bytes[1]);
        if (!(flags & 0x40)) {
            mode->bytes[1] = keep_detected_flags(flags) | 0x40;
            if (isatty(descriptor))
                ((DescriptorMode *)((unsigned char *)descriptor_modes + offset))->bytes[1] |= 0x20;
        }
    }
    return keep_mode_table(descriptor_modes)[keep_descriptor_index(descriptor)].value;
}

void set_io_mode(int descriptor, DescriptorMode mode)
{
    unsigned long value;
    int offset;
    DescriptorMode *table;
    mode.bytes[1] |= 0x40;
    value = keep_new_mode(mode.value);
    offset = keep_descriptor_index(descriptor);
    table = keep_mode_table(descriptor_modes);
    offset = keep_descriptor_index(offset * sizeof(DescriptorMode));
    ((DescriptorMode *)((unsigned char *)table + offset))->value = value;
}

/* DOS close reports failure in carry. Move it to the sign bit. */
extern int dos_close_descriptor(int, int);
#pragma aux dos_close_descriptor = "mov ah,3eh" "int 21h" "rcl eax,1" "ror eax,1" parm [eax] [ebx] value [eax] modify exact [eax];
extern void reset_descriptor_mode(DescriptorMode, int);
#pragma aux reset_descriptor_mode "set_io_mode_" parm [edx] [eax] modify exact [eax edx];
extern void set_errno(int);
#pragma aux set_errno modify exact [eax];

int close_descriptor(int descriptor)
{
    int saved = keep_descriptor_index(descriptor);
    DescriptorMode mode;
    if (dos_close_descriptor(descriptor, descriptor) >= 0) {
        mode.value = 0;
        reset_descriptor_mode(mode, keep_descriptor_index(saved));
        return 0;
    }
    set_errno(4);
    return -1;
}

/* Preserve the standalone tail entry used by the C runtime. */
extern int dos_remove_transfer(const char *);
#pragma aux dos_remove_transfer "remove_file_dos_" aborts modify exact [eax];
int remove(const char *filename)
{
    return dos_remove_transfer(filename);
}

/* DOS function 41h expects the filename in DS:EDX. */
extern int dos_remove_file(const char *, const char *);
#pragma aux dos_remove_file = "mov ah,41h" "int 21h" "rcl eax,1" "ror eax,1" parm [eax] [edx] value [eax] modify exact [eax edx];
extern int set_dos_errno(int);
#pragma aux set_dos_errno modify exact [eax];

int remove_file_dos(const char *filename)
{
    int status = dos_remove_file(filename, filename);
    if (status < 0)
        return set_dos_errno(status & 0xffff);
    return 0;
}

/* DOS ioctl 4400h returns the device flags in DX. */
extern int dos_device_flags(int, int);
#pragma aux dos_device_flags = "mov al,0" "mov ah,44h" "int 21h" "rcl edx,1" "ror edx,1" parm [eax] [ebx] value [edx] modify exact [eax ecx edx];
int isatty(int);
#pragma aux isatty parm routine [eax] modify exact [eax];
int isatty(int descriptor)
{
    return (dos_device_flags(descriptor, descriptor) & 0x80) != 0;
}

/* DOS read takes the descriptor in BX, size in CX and destination in DS:EDX. */
extern int dos_read_descriptor(int, void *, unsigned, int);
#pragma aux dos_read_descriptor = "mov ah,3fh" "int 21h" "rcl eax,1" "ror eax,1" parm [eax] [edx] [ecx] [ebx] value [eax] modify exact [eax];
extern void keep_read_status(int);
#pragma aux keep_read_status = parm [edx] modify exact [];
int read_descriptor_raw(int, void *, unsigned);
#pragma aux read_descriptor_raw modify exact [eax ebx edx];
int read_descriptor_raw(int descriptor, void *buffer, unsigned size)
{
    int status = dos_read_descriptor(descriptor, buffer, size, descriptor);
    keep_read_status(status);
    if (status < 0)
        return set_dos_errno(status & 0xffff);
    return status;
}

extern int pending_console_char;
extern int clear_value_in_edx(int);
#pragma aux clear_value_in_edx = parm [edx] value [edx] modify exact [];
/* DOS input service 01h echoes the character, while 08h reads without echo. */
extern unsigned dos_read_console(unsigned char);
#pragma aux dos_read_console = "int 21h" parm [ah] value [eax] modify exact [eax];
int read_console_character(void);
#pragma aux read_console_character modify exact [eax];
int read_console_character(void)
{
    int zero = clear_value_in_edx(0);
    int key = pending_console_char;
    pending_console_char = zero;
    if (!key)
        return dos_read_console(1) & 0xff;
    return key;
}

int getch(void);
#pragma aux getch modify exact [eax];
int getch(void)
{
    int zero = clear_value_in_edx(0);
    int key = pending_console_char;
    pending_console_char = zero;
    if (!key)
        return dos_read_console(8) & 0xff;
    return key;
}

extern long lseek(int, long, int);
#pragma aux lseek modify exact [eax edx ebx];
extern int initial_origin_in_ebx(int);
#pragma aux initial_origin_in_ebx = parm [ebx] value [ebx] modify exact [];
extern int descriptor_in_ecx(int);
#pragma aux descriptor_in_ecx = parm [ecx] value [ecx] modify exact [];
extern long position_in_esi(long);
#pragma aux position_in_esi = parm [esi] value [esi] modify exact [];
extern long position_in_edi(long);
#pragma aux position_in_edi = parm [edi] value [edi] modify exact [];
long filelength(int descriptor);
#pragma aux filelength modify exact [eax];
long filelength(int descriptor)
{
    int handle = descriptor_in_ecx(descriptor);
    int origin = initial_origin_in_ebx(1);
    long position = lseek(descriptor, 0, origin);
    long saved = position_in_esi(position);
    long length;
    if (position == -1)
        return position;
    length = position_in_edi(lseek(handle, 0, 2));
    lseek(handle, saved, 0);
    return length;
}
