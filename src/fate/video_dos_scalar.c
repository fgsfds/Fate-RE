/* Genuine scalar-ABI transfer context. Only its two segment-record stores
 * supply production bytes. The legacy BIOS call remains assembly; this private
 * context initializes the BIOS helper DS and is not a direct replacement. */
#include "dpmiregs.h"

extern unsigned video_dos_buffer_size, video_dos_allocation;
extern unsigned video_dos_real_segment;
extern const char video_dos_allocation_error[];

extern int int386(int, DpmiRegisters *, DpmiRegisters *);
#pragma aux int386 modify exact [eax ebx edx];
extern int printf(const char *, ...);
#pragma aux printf parm caller [] modify exact [eax];
extern void runtime_exit(int);
extern void main_prepare(void (*)(void));
#pragma aux main_prepare modify exact [eax];
extern void free_video_dos_memory(void);

extern unsigned short FP_SEG(const void __far *);
#pragma aux FP_SEG = parm caller [eax dx] value [dx] modify exact [];

/* EAX/EBX carry offsets, DX/CX carry selectors, and RET 4 pops length. */
extern int copy_video_far_scalar(void *, unsigned short, const void *, unsigned short, unsigned);
#pragma aux copy_video_far_scalar "_fmemcpy_" parm routine [eax] [edx] [ebx] [ecx] [] value [eax] modify exact [eax ebx ecx edx];

extern int dpmi_real_mode_far_call(int, const BiosRegisters *, BiosRegisters *, DpmiSegments *);
#pragma aux dpmi_real_mode_far_call parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];

extern BiosRegisters *bios_in_esi(BiosRegisters *);
#pragma aux bios_in_esi = parm [esi] value [esi] modify exact [];
extern void *buffer_in_edi(void *);
#pragma aux buffer_in_edi = parm [edi] value [edi] modify exact [];

int video_transfer_scalar_context(BiosRegisters *, void *, unsigned);
#pragma aux video_transfer_scalar_context parm routine [eax] [edx] [ebx] modify exact [eax ebx edx];

int video_transfer_scalar_context(BiosRegisters *bios, void *buffer, unsigned length)
{
    struct {
        DpmiRegisters registers;
        /* At +0x1c: ES, CS, SS, DS, FS, GS. FS is scratch for the
         * protected buffer selector, which the BIOS helper preserves. */
        DpmiSegments segments;
    } frame;
    BiosRegisters *bios_regs = bios_in_esi(bios);
    void *video_buffer = buffer_in_edi(buffer);

    if (video_dos_allocation == 0) {
        frame.registers.eax.words.low = 0x100;
        frame.registers.ebx.words.low =
            (unsigned short)((long)(video_dos_buffer_size + 15u) >> 4);
        int386(0x31, &frame.registers, &frame.registers);
        restore_dos_segments();
        if (frame.registers.carry.value != 0) {
            printf(video_dos_allocation_error);
            runtime_exit(0);
        }
        video_dos_allocation = frame.registers.edx.words.low;
        video_dos_real_segment = frame.registers.eax.words.low;
        main_prepare(free_video_dos_memory);
    }

    frame.segments.es = (unsigned short)video_dos_real_segment;
    frame.segments.fs = FP_SEG((const void __far *)video_buffer);
    bios_regs->di = 0;
    copy_video_far_scalar(0, (unsigned short)video_dos_allocation,
                    video_buffer, frame.segments.fs, length);
    /* Both VBE information services take their buffer through ES:DI. */
    frame.segments.ds = 0;
    dpmi_real_mode_far_call(0x10, bios_regs, bios_regs, &frame.segments);
    return copy_video_far_scalar(video_buffer, frame.segments.fs,
                           0, (unsigned short)video_dos_allocation, length);
}
