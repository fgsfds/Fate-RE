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

/* The far pointer already carries its selector in DX. */
extern unsigned short FP_SEG(const void __far *);
#pragma aux FP_SEG = parm caller [eax dx] value [dx];

extern void __far *copy_far_memory(void __far *, const void __far *, unsigned);
#pragma aux copy_far_memory "_fmemcpy_" parm routine [dx eax] [cx ebx] [] modify exact [eax ebx ecx edx];

extern int dpmi_real_mode_far_call(int, const BiosRegisters *, BiosRegisters *, DpmiSegments *);
#pragma aux dpmi_real_mode_far_call parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];

/* Guarded entry, transfer and frame phases link into production. The private
 * contexts initialize helper DS; the legacy BIOS call remains assembly. */
#ifdef VIDEO_RETURN_BUFFER
#define VIDEO_RESULT void *
#define VIDEO_CONTEXT video_transfer_buffer_context
#pragma aux video_transfer_buffer_context parm routine [eax] [edx] [ebx] value [edi] modify exact [eax ebx edx];
#else
#define VIDEO_RESULT int
#define VIDEO_CONTEXT get_vesa_mode_info
#pragma aux get_vesa_mode_info parm routine [eax] [edx] [ebx] modify exact [eax ebx edx];
#endif
VIDEO_RESULT VIDEO_CONTEXT(BiosRegisters *, void *, unsigned);
VIDEO_RESULT VIDEO_CONTEXT(BiosRegisters *bios, void *buffer, unsigned length)
{
    struct {
        DpmiRegisters registers;
        DpmiSegments segments;
    } frame;

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

    frame.segments.fs = FP_SEG((const void __far *)buffer);
    frame.segments.es = (unsigned short)video_dos_real_segment;
    bios->di = 0;
    copy_far_memory(
        (void __far *)((__segment)video_dos_allocation :> (void *)0),
        (const void __far *)((__segment)frame.segments.fs :> buffer),
        length);
    frame.segments.ds = 0;
    dpmi_real_mode_far_call(0x10, bios, bios, &frame.segments);
#ifdef VIDEO_RETURN_BUFFER
    copy_far_memory(
        (void __far *)((__segment)frame.segments.fs :> buffer),
        (const void __far *)((__segment)video_dos_allocation :> (void *)0),
        length);
    return buffer;
#else
    return (int)(unsigned)(void *)copy_far_memory(
        (void __far *)((__segment)frame.segments.fs :> buffer),
        (const void __far *)((__segment)video_dos_allocation :> (void *)0),
        length);
#endif
}
