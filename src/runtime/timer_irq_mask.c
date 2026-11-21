/* Mask and unmask the DOS timer interrupt through the 8259 PIC. */
extern int pit_programming_enabled;

void mask_timer_irq(void);
#pragma aux mask_timer_irq aborts;
void unmask_timer_irq(void);
#pragma aux unmask_timer_irq aborts;
void program_pit(int divisor);
#pragma aux program_pit parm [] aborts;

extern void save_timer_registers(void);
#pragma aux save_timer_registers = "push ebp" "db 8bh, 0ech" "push esi" "push edi" "push ebx" \
    "push ecx" "push fs" "push gs" "push es" modify exact [];

/* Four NOPs pad the enabled path to the original alignment. */
extern void timer_padding(void);
#pragma aux timer_padding = "nop" "nop" "nop" "nop" modify exact [];

extern void mask_pic(void);
#pragma aux mask_pic = "mov dx,21h" "in al,dx" "or al,1" "out dx,al" modify exact [eax edx];

extern void unmask_pic(void);
#pragma aux unmask_pic = "mov dx,21h" "in al,dx" "and al,0feh" "out dx,al" modify exact [eax edx];

extern void program_pit_command(void);
#pragma aux program_pit_command = "mov dx,43h" "mov al,36h" "out dx,al" modify exact [eax edx];

/* The divisor is the caller's first stack argument at [ebp + 8]. */
extern void program_pit_divisor(void);
#pragma aux program_pit_divisor = "mov dx,40h" "mov eax,[ebp+8]" "out dx,al" \
    "db 8ah, 0c4h" "out dx,al" modify exact [eax edx];

extern void restore_timer_registers(void);
#pragma aux restore_timer_registers = "pop es" "pop gs" "pop fs" "pop ecx" "pop ebx" \
    "pop edi" "pop esi" "pop ebp" "ret" modify exact [];

void mask_timer_irq(void)
{
    save_timer_registers();
    if (pit_programming_enabled) {
        timer_padding();
        mask_pic();
    }
    restore_timer_registers();
}

void unmask_timer_irq(void)
{
    save_timer_registers();
    if (pit_programming_enabled) {
        timer_padding();
        unmask_pic();
    }
    restore_timer_registers();
}

void program_pit(int divisor)
{
    save_timer_registers();
    if (pit_programming_enabled) {
        timer_padding();
        mask_pic();
        program_pit_command();
        program_pit_divisor();
        unmask_pic();
    }
    restore_timer_registers();
}
