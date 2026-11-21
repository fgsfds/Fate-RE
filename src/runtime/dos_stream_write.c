/* Watcom register assignments for the DOS and C runtime calls. */
extern long reg_eax(void);
#pragma aux reg_eax = value [eax] modify exact [];
extern void hold_eax(long);
#pragma aux hold_eax = parm [eax] modify exact [];
extern void hold_ebx(long);
#pragma aux hold_ebx = parm [ebx] modify exact [];
extern void hold_ecx(long);
#pragma aux hold_ecx = parm [ecx] modify exact [];
extern long reg_edx(void);
#pragma aux reg_edx = value [edx] modify exact [];
extern void hold_edx(long);
#pragma aux hold_edx = parm [edx] modify exact [];
extern long reg_esi(void);
#pragma aux reg_esi = value [esi] modify exact [];
extern void hold_esi(long);
#pragma aux hold_esi = parm [esi] modify exact [];
extern void hold_edi(long);
#pragma aux hold_edi = parm [edi] modify exact [];
extern long reg_ebp(void);
#pragma aux reg_ebp = value [ebp] modify exact [];
extern void save_write_count(unsigned);
#pragma aux save_write_count = "mov ebp,ebx" parm [ebx] modify exact [];

extern unsigned long get_io_mode(int);
#pragma aux get_io_mode modify exact [eax];
extern long set_dos_errno(unsigned);
#pragma aux set_dos_errno modify exact [eax];
extern void set_errno(int);
#pragma aux set_errno modify exact [eax];

/* Save the historical frame slots used across both DOS interrupts. */
extern void save_write_frame(void);
#pragma aux save_write_frame = "push ecx" "push esi" "push edi" "push ebp" "sub esp,4" modify exact [];
extern void restore_write_frame(void);
#pragma aux restore_write_frame = "add esp,4" "pop ebp" "pop edi" "pop esi" "pop ecx" modify exact [];
extern void save_write_buffer(const void *);
#pragma aux save_write_buffer = "mov [esp],edx" parm [edx] modify exact [];
extern void load_write_buffer(void);
#pragma aux load_write_buffer = "mov edx,[esp]" modify exact [edx];
extern void set_seek_origin(unsigned char);
#pragma aux set_seek_origin = parm [al] modify exact [];
extern void set_dos_function(unsigned char);
#pragma aux set_dos_function = parm [ah] modify exact [];
/* Copy DOS carry to the sign bit of the returned offset or count. */
extern void dos_seek(void);
#pragma aux dos_seek = "int 21h" "rcl dx,1" "ror dx,1" modify exact [eax edx];
extern unsigned short low_ax(void);
#pragma aux low_ax = value [ax] modify exact [];
extern void put_dx(unsigned short);
#pragma aux put_dx = parm [dx] modify exact [];
extern long reg_ebx(void);
#pragma aux reg_ebx = value [ebx] modify exact [];
extern long reg_ecx(void);
#pragma aux reg_ecx = value [ecx] modify exact [];
/* Keep the count and buffer moves ahead of the DOS function byte. */
extern void keep_write_arguments(long, long, long);
#pragma aux keep_write_arguments = parm [edx] [ebx] [ecx] modify exact [eax];

extern void dos_write_bytes(void);
#pragma aux dos_write_bytes = "int 21h" "rcl eax,1" "ror eax,1" modify exact [eax];

long write_stream_descriptor(int descriptor, const void *buffer, unsigned count);
#pragma aux write_stream_descriptor modify exact [eax ebx ecx edx esi edi];
long write_stream_descriptor(int descriptor, const void *buffer, unsigned count)
{
    long status;
    (void)descriptor;
    save_write_frame();
    hold_esi(reg_eax());
    save_write_buffer(buffer);
    save_write_count(count);
    if (!(get_io_mode(reg_eax()) & 0x80))
        goto write_bytes;
    set_seek_origin(2);
    hold_ebx(reg_esi());
    hold_edx(0);
    set_dos_function(0x42);
    hold_ecx((unsigned long)reg_edx() >> 16);
    dos_seek();
    /* Combine DX:AX into the signed result, including the carry sign bit. */
    hold_edx((unsigned long)reg_edx() << 16);
    put_dx(low_ax());
    hold_edi(reg_edx());
    if (reg_edx() >= 0)
        goto write_bytes;
    status = (unsigned short)reg_edx();
translate_error:
    hold_eax(set_dos_errno(status));
    goto done;
write_bytes:
    load_write_buffer();
    hold_ebx(reg_esi());
    hold_ecx(reg_ebp());
    keep_write_arguments(reg_edx(), reg_ebx(), reg_ecx());
    set_dos_function(0x40);
    dos_write_bytes();
    hold_esi(reg_eax());
    hold_edi(reg_eax());
    hold_edx(reg_eax());
    if (reg_eax() < 0) {
        status = (unsigned short)reg_esi();
        goto translate_error;
    }
    if (reg_eax() != reg_ebp())
        set_errno(12);
    hold_eax(reg_edx());
done:
    restore_write_frame();
    return reg_eax();
}
