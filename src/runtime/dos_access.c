/* Check file access with the DOS 43h attribute service. */
extern int dosret0(int code, int flag);
#pragma aux dosret0 parm [eax] [edx] value [eax] modify exact [eax];

/* These stages share the caller's frame. EAX enters with the filename and
 * EDX with the mode; the final stage returns the translated errno. */
void access(void);
#pragma aux access aborts;
void access_translate(void);
#pragma aux access_translate aborts;

extern void save_access_registers(void);
#pragma aux save_access_registers = "push ebx" "push ecx" modify exact [];

/* DOS 43h returns the attribute word in CX and sets carry on error. */
extern void dos_get_attributes(void);
#pragma aux dos_get_attributes = "xor eax,eax" "mov ah,43h" "int 21h" "db 72h, 0fh" /* marker-rel8 +3,+4 */ modify exact [eax ecx];

extern void check_write_mode(void);
#pragma aux check_write_mode = "test bl,2" "db 74h, 0ah" /* marker-rel8 +2,+3 */ modify exact [];

extern void check_readonly(void);
#pragma aux check_readonly = "test cl,1" "db 74h, 05h" /* marker-rel8 +1,+2 */ modify exact [];

extern void deny_access(void);
#pragma aux deny_access = "mov al,0" "mov ah,6" "stc" modify exact [eax];

extern void translate_carry(void);
#pragma aux translate_carry = "sbb ecx,ecx" "mov cx,ax" modify exact [ecx];

extern void copy_translated_result(void);
#pragma aux copy_translated_result = "mov eax,ecx" "mov ebx,eax" "mov edx,eax" modify exact [eax ebx edx];

extern void restore_access_registers(void);
#pragma aux restore_access_registers = "pop ecx" "pop ebx" "ret" modify exact [];

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

void access(void)
{
    save_access_registers();
    in_bx(from_dx());
    in_dx(from_ax());
    dos_get_attributes();
    check_write_mode();
    check_readonly();
    deny_access();
}

void access_translate(void)
{
    translate_carry();
    copy_translated_result();
    in_bx(from_bx() & 0xffffUL);
    in_dx(from_dx() >> 16);
    in_ax(from_bx());
    dosret0(from_ax(), from_dx());
    restore_access_registers();
}
