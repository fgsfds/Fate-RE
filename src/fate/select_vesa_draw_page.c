#include "dpmiregs.h"

typedef void (*VesaWindow)(void);
extern VesaWindow vesa_pm_set_window;

extern long skip_bank_switch, linear_framebuffer_enabled, use_software_framebuffer;
extern unsigned char bank_shift;
extern void *software_framebuffer, *draw_page_address, *linear_page_addresses[];

extern int dpmi_real_mode_interrupt(int, const BiosRegisters *, BiosRegisters *);
#pragma aux dpmi_real_mode_interrupt parm [eax] [edx] [ebx] modify exact [eax ebx edx];

/* Call the VESA protected-mode Set Window entry with the DOS register ABI. */
extern void call_vesa_window(unsigned, unsigned, unsigned);
#pragma aux call_vesa_window = "call dword ptr [vesa_pm_set_window]" parm [eax] [edx] [ecx] modify exact [eax edx ecx];

/* Keep the real-mode BIOS input words in the original Watcom registers. */
extern unsigned hold_window_ax(unsigned);
#pragma aux hold_window_ax = parm [edx] value [edx] modify exact [];
extern unsigned char hold_bank_shift(unsigned char);
#pragma aux hold_bank_shift = parm [cl] value [cl] modify exact [];
extern unsigned zero_window_number(void);
#pragma aux zero_window_number = "xor ebx, ebx" value [ebx] modify exact [];

/* The shared epilogue only restores the saved registers. */
extern void release_graphics_frame(void);
#pragma aux release_graphics_frame = "add esp, 10h" modify exact [];
extern void shared_graphics_epilogue(void);
#pragma aux shared_graphics_epilogue aborts modify exact [];

void select_vesa_draw_page(unsigned page)
{
    BiosRegisters regs;

    if (!skip_bank_switch && !linear_framebuffer_enabled) {
        draw_page_address = (void *)0xa0000;
        if (vesa_pm_set_window) {
            call_vesa_window(0, page << bank_shift, 0);
        } else {
            unsigned ax;
            unsigned char shift;
            unsigned window_number;

            ax = hold_window_ax(0x4f05);
            shift = hold_bank_shift(bank_shift);
            window_number = zero_window_number();
            regs.ax = ax;
            regs.bx = window_number;
            regs.dx = page << shift;
            dpmi_real_mode_interrupt(0x10, &regs, &regs);
        }
    }

    if (use_software_framebuffer)
        draw_page_address = software_framebuffer;
    else if (linear_framebuffer_enabled)
        draw_page_address = linear_page_addresses[page];

    release_graphics_frame();
    shared_graphics_epilogue();
}
