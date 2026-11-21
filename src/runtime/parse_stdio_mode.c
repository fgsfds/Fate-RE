enum {
    MODE_READ = 1,
    MODE_WRITE = 2,
    MODE_UPDATE = MODE_READ | MODE_WRITE,
    MODE_BINARY = 0x40,
    MODE_APPEND = 0x80,
    DOS_DEFAULT_BINARY = 0x200
};

extern unsigned default_file_mode;
extern unsigned lower_mode(int);
#pragma aux lower_mode "tolower_" modify exact [eax];
extern int set_errno(int);
#pragma aux set_errno modify exact [eax];
extern void mode_in_edx(const char *);
#pragma aux mode_in_edx = parm [edx] modify exact [];
extern const unsigned char *mode_pointer(void);
#pragma aux mode_pointer = value [edx] modify exact [];
extern unsigned clear_eax(void);
#pragma aux clear_eax = "xor eax,eax" value [eax] modify exact [eax];
extern void set_first_char(unsigned char);
#pragma aux set_first_char = parm [al] modify exact [];
extern unsigned eax_value(void);
#pragma aux eax_value = value [eax] modify exact [];
extern unsigned char al_value(void);
#pragma aux al_value = value [al] modify exact [];
/* Keep the flag candidates in the original Watcom registers. */
extern void set_eax(unsigned);
#pragma aux set_eax = parm [eax] modify exact [];
extern void set_ebx(unsigned);
#pragma aux set_ebx = parm [ebx] modify exact [];
extern unsigned ebx_value(void);
#pragma aux ebx_value = value [ebx] modify exact [];
extern void set_ecx(unsigned);
#pragma aux set_ecx = parm [ecx] modify exact [];
extern unsigned ecx_value(void);
#pragma aux ecx_value = value [ecx] modify exact [];
extern void set_next_char(unsigned char);
#pragma aux set_next_char = parm [cl] modify exact [];
extern unsigned char cl_value(void);
#pragma aux cl_value = value [cl] modify exact [];
extern void set_flag_byte(unsigned char);
#pragma aux set_flag_byte = parm [bl] modify exact [];
extern unsigned char bl_value(void);
#pragma aux bl_value = value [bl] modify exact [];

unsigned __open_flags(const char *);
#pragma aux __open_flags modify exact [eax];
unsigned __open_flags(const char *mode)
{
    volatile unsigned char first;

    mode_in_edx(mode);
    clear_eax();
    set_first_char(*mode_pointer());
    set_ebx(0);
    first = lower_mode(eax_value());
    if (al_value() != 'r' && al_value() != 'w' && al_value() != 'a') {
        set_errno(9);
        return 0;
    }
    set_eax(ebx_value());
    set_next_char(mode_pointer()[1]);
    set_first_char(al_value() | MODE_UPDATE);
    if (cl_value() == '+') {
        set_ebx(eax_value());
        set_next_char(mode_pointer()[2]);
        set_first_char(al_value() | MODE_BINARY);
        if (cl_value() == 'b')
            goto binary;
        if (cl_value() == 't')
            goto access;
        if (default_file_mode != DOS_DEFAULT_BINARY)
            goto access;
binary:
        set_ebx(eax_value());
        goto access;
    }
    set_ecx(ebx_value());
    set_next_char(cl_value() | MODE_BINARY);
    if (mode_pointer()[1] == 'b') {
        set_first_char(mode_pointer()[2]);
        set_ebx(ecx_value());
        if (al_value() != '+')
            goto access;
        set_next_char(cl_value() | MODE_UPDATE);
        goto modified;
    }
    /* The text modifier shares the original conditional branch. */
    if (mode_pointer()[1] == 't') {
        if (mode_pointer()[2] != '+')
            goto access;
        goto binary;
    }
    if (default_file_mode != DOS_DEFAULT_BINARY)
        goto access;
modified:
    set_ebx(ecx_value());
access:
    set_first_char(first);
    if (al_value() == 'w')
        set_flag_byte(bl_value() | MODE_WRITE);
    else if (al_value() == 'a')
        set_flag_byte(bl_value() | MODE_WRITE | MODE_APPEND);
    else
        set_flag_byte(bl_value() | MODE_READ);
    return ebx_value();
}
