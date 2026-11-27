/* Set the binary-mode bit on a DOS file handle, extending device handles via IOCTL. */
extern int get_io_mode(int handle);
#pragma aux get_io_mode parm [eax] value [eax] modify exact [eax];
extern int set_io_mode(int handle, int mode);
#pragma aux set_io_mode parm [eax] [edx] value [eax] modify exact [eax];
extern int set_dos_errno(int code);
#pragma aux set_dos_errno parm [eax] value [eax] modify exact [eax];

/* These stages share the caller's frame. EAX enters with the handle and the
 * final stage returns zero on success. */
void __set_binary(void);
#pragma aux __set_binary aborts;
void set_binary_device_get(void);
#pragma aux set_binary_device_get aborts;
void set_binary_dos_error(void);
#pragma aux set_binary_dos_error aborts;
void set_binary_device_set(void);
#pragma aux set_binary_device_set aborts;
void set_binary_success(void);
#pragma aux set_binary_success aborts;
void set_binary_restore(void);
#pragma aux set_binary_restore aborts;

extern void save_binary_registers(void);
#pragma aux save_binary_registers = "push ebx" "push ecx" "push edx" "push esi" "sub esp,4" modify exact [];

extern void check_device_bit(void);
#pragma aux check_device_bit = "test bh,20h" "db 74h, 3bh" /* marker-rel8 +4,+5 */ modify exact [];

/* DOS IOCTL 0x44: get (AL=0) or set (AL=1) the device information word. */
extern void dos_get_device_info(void);
#pragma aux dos_get_device_info = "mov al,0" "mov ah,44h" "int 21h" "rcl edx,1" "ror edx,1" \
    "mov [esp],edx" "test edx,edx" "db 7dh, 0dh" /* marker-rel8 +2,+3 */ modify exact [eax edx];

extern void dos_set_device_info(void);
#pragma aux dos_set_device_info = "mov dl,[esp]" "mov ebx,esi" "or dl,20h" "mov dh,0" "mov al,1" "mov ah,44h" \
    "int 21h" "rcl edx,1" "ror edx,1" "mov [esp],edx" "test edx,edx" "db 7ch, 0d8h" /* marker-rel8 -3,-2 */ modify exact [eax ebx edx];

extern unsigned short error_word_in_ax(void);
#pragma aux error_word_in_ax = "mov ax,[esp]" value [ax] modify exact [];
extern void finish_binary_error(void);
#pragma aux finish_binary_error = "db 0ebh, 1dh" /* marker-rel8 +1,+2 */ modify exact [];
extern void restore_binary_registers(void);
#pragma aux restore_binary_registers = "add esp,4" "pop esi" "pop edx" "pop ecx" "pop ebx" "ret" modify exact [];

extern unsigned long from_ax(void);
#pragma aux from_ax = value [eax] modify exact [];
extern void in_ax(unsigned long);
#pragma aux in_ax = parm [eax] modify exact [];
extern unsigned long from_bx(void);
#pragma aux from_bx = value [ebx] modify exact [];
extern void in_bx(unsigned long);
#pragma aux in_bx = parm [ebx] modify exact [];
extern unsigned long from_dx(void);
#pragma aux from_dx = value [edx] modify exact [];
extern void in_dx(unsigned long);
#pragma aux in_dx = parm [edx] modify exact [];
extern unsigned long from_si(void);
#pragma aux from_si = value [esi] modify exact [];
extern void in_si(unsigned long);
#pragma aux in_si = parm [esi] modify exact [];
extern unsigned char from_al(void);
#pragma aux from_al = value [al] modify exact [];
extern void in_al(unsigned char);
#pragma aux in_al = parm [al] modify exact [];
extern void in_ax_word(unsigned short);
#pragma aux in_ax_word = parm [ax] modify exact [];

void __set_binary(void)
{
    save_binary_registers();
    in_si(from_ax());
    get_io_mode(from_ax());
    in_al(from_al() | 0x40);
    in_bx(from_ax());
    in_ax(from_si());
    in_dx(from_bx());
    set_io_mode(from_ax(), from_dx());
    check_device_bit();
}

void set_binary_device_get(void)
{
    in_bx(from_si());
    dos_get_device_info();
}

void set_binary_dos_error(void)
{
    in_ax(0);
    in_ax_word(error_word_in_ax());
    set_dos_errno(from_ax());
    finish_binary_error();
}

void set_binary_device_set(void)
{
    dos_set_device_info();
}

void set_binary_success(void)
{
    in_ax(0);
}

void set_binary_restore(void)
{
    restore_binary_registers();
}
