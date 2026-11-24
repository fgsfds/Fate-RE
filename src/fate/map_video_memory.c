/* Complete DPMI video mapper. Checked compiler phases retain the original
 * field and register order in two preparation blocks. Every instruction is
 * selected once; the existing segment restoration helper contributes 30 bytes. */
#include "dpmiregs.h"

extern unsigned long mapped_video_base;
extern const char video_selector_allocation_error[];
extern const char video_physical_mapping_error[];
extern const char video_selector_base_error[];
extern const char video_selector_limit_error[];

extern int int386(int, DpmiRegisters *, DpmiRegisters *);
#pragma aux int386 modify exact [eax ebx edx];
extern int printf(const char *, ...);
#pragma aux printf parm caller [] modify exact [eax];
extern void runtime_exit(int);
#pragma aux runtime_exit modify exact [eax];

/* INT 31h calls leave the protected-mode selector live in ECX. */
extern unsigned selector_in_ecx(unsigned);
#pragma aux selector_in_ecx = parm [ecx] value [ecx] modify exact [];

/* Keep the two halves of the mapped address in their full-width registers. */
extern unsigned long high_word_in_edx(unsigned long);
#pragma aux high_word_in_edx = parm [edx] value [edx] modify exact [];
extern unsigned long low_word_in_ebx(unsigned long);
#pragma aux low_word_in_ebx = parm [ebx] value [ebx] modify exact [];
extern unsigned long sum_in_edx(unsigned long);
#pragma aux sum_in_edx = parm [edx] value [edx] modify exact [];

void __far *map_video_memory(unsigned long);
#pragma aux map_video_memory parm routine [eax] value [dx eax] modify exact [eax edx];

void __far *map_video_memory(unsigned long physical_address)
{
    DpmiRegisters regs;
    unsigned selector;
    unsigned long linear_address;

    regs.eax.words.low = 0x0000;
    regs.ecx.words.low = 1;
    int386(0x31, &regs, &regs);
    restore_dos_segments();
    if (regs.carry.value != 0) {
        printf(video_selector_allocation_error);
        runtime_exit(0);
    }

    selector = selector_in_ecx(regs.eax.words.low);
    regs.eax.words.low = 0x0009;
    regs.ebx.words.low = (unsigned short)selector;
    regs.ecx.words.low = 0x8092;
    int386(0x31, &regs, &regs);
    restore_dos_segments();

    regs.eax.words.low = 0x0800;
    regs.ebx.words.low = (unsigned short)((long)physical_address >> 16);
    regs.ecx.words.low = (unsigned short)physical_address;
    regs.esi.words.low = 0x003f;
    regs.edi.words.low = 0xffff;
    int386(0x31, &regs, &regs);
    restore_dos_segments();
    if (regs.carry.value != 0) {
        printf(video_physical_mapping_error);
        runtime_exit(0);
    }

    linear_address = sum_in_edx((high_word_in_edx(regs.ebx.words.low) << 16)
        + low_word_in_ebx(regs.ecx.words.low));
    mapped_video_base = linear_address;
    regs.eax.words.low = 0x0007;
    regs.ebx.words.low = (unsigned short)selector;
    regs.ecx.words.low = (unsigned short)((long)linear_address >> 16);
    regs.edx.words.low = (unsigned short)mapped_video_base;
    int386(0x31, &regs, &regs);
    restore_dos_segments();
    if (regs.carry.value != 0) {
        printf(video_selector_base_error);
        runtime_exit(0);
    }

    regs.eax.words.low = 0x0008;
    regs.ebx.words.low = (unsigned short)selector;
    regs.ecx.words.low = 0x003f;
    regs.edx.words.low = 0xffff;
    int386(0x31, &regs, &regs);
    restore_dos_segments();
    if (regs.carry.value != 0) {
        printf(video_selector_limit_error);
        runtime_exit(0);
    }

    return (void __far *)((__segment)selector :> (void *)0);
}
