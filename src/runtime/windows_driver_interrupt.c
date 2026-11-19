/* Dispatch the Windows driver call when the multiplex interrupt reports it. */
void windows_driver_interrupt(void);
#pragma aux windows_driver_interrupt aborts;
void windows_driver_interrupt_stop(void);
#pragma aux windows_driver_interrupt_stop aborts;

extern void save_registers(void);
#pragma aux save_registers = "push ebp" "db 8bh, 0ech" "push esi" "push edi" "push ebx" \
    "push ecx" "push fs" "push gs" "push es" modify exact [eax ebx ecx edx esi edi];

/* int 2Fh AX=1600h returns the Windows driver version in AL. */
extern unsigned char int_2f(void);
#pragma aux int_2f = "mov ax,1600h" "int 2fh" value [al] modify exact [eax];

extern void timer_padding(void);
#pragma aux timer_padding = "nop" "nop" "nop" "nop" modify exact [];

extern void windows_call(void);
#pragma aux windows_call = "mov ah,81h" "mov al,0bh" "mov ebx,[ebp+8]" \
    "db 66h,33h,0d2h" "int 4bh" "mov ax,0" modify exact [eax ebx edx];

extern void windows_call_stop(void);
#pragma aux windows_call_stop = "mov ah,81h" "mov al,0ch" "mov ebx,[ebp+8]" \
    "db 66h,33h,0d2h" "int 4bh" "mov ax,0" modify exact [eax ebx edx];

extern void restore_registers(void);
#pragma aux restore_registers = "pop es" "pop gs" "pop fs" "pop ecx" "pop ebx" \
    "pop edi" "pop esi" "pop ebp" "ret" modify exact [];

void windows_driver_interrupt(void)
{
    save_registers();
    if (int_2f() == 3) {
        timer_padding();
        windows_call();
    }
    restore_registers();
}

void windows_driver_interrupt_stop(void)
{
    save_registers();
    if (int_2f() == 3) {
        timer_padding();
        windows_call_stop();
    }
    restore_registers();
}
