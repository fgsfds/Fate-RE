#include "rtstream.h"

/* The register-call allocator retains the stream pointer in EDX. */
extern void save_stream(RuntimeStream *);
#pragma aux save_stream = parm [edx] modify exact [];
extern RuntimeStream *incoming_stream(void);
#pragma aux incoming_stream = value [eax] modify exact [];
extern RuntimeStream *current_stream(void);
#pragma aux current_stream = value [edx] modify exact [];
extern unsigned char *pointer_in_eax(unsigned char *);
#pragma aux pointer_in_eax = parm [eax] value [eax] modify exact [];
extern unsigned char flags_in_cl(unsigned char);
#pragma aux flags_in_cl = parm [cl] value [cl] modify exact [];
extern void detect_stream_mode(RuntimeStream *);
#pragma aux detect_stream_mode "detect_terminal_" modify exact [eax];
extern void *malloc(unsigned);
#pragma aux malloc modify exact [eax];
extern unsigned char flags_in_ah(unsigned char);
#pragma aux flags_in_ah = parm [ah] value [ah] modify exact [];
extern unsigned char flags_in_ch(unsigned char);
#pragma aux flags_in_ch = parm [ch] value [ch] modify exact [];
unsigned char *allocate_stream_buffer(RuntimeStream *);
#pragma aux allocate_stream_buffer modify exact [eax];
unsigned char *allocate_stream_buffer(RuntimeStream *stream)
{
    unsigned char *allocated;
    unsigned char flags, direct_flags;

    save_stream(stream);
    detect_stream_mode(incoming_stream());

    if (!current_stream()->capacity) {
        flags = flags_in_ah(current_stream()->flags.bytes[1]);
        if (flags & 2)
            current_stream()->capacity = 0x86;
        else if (flags & 4)
            *(volatile unsigned *)&current_stream()->capacity = 1;
        else
            current_stream()->capacity = 0x1000;
    }
    allocated = malloc(current_stream()->capacity);
    *(void *volatile *)&current_stream()->buffer = allocated;
    if (!allocated) {
        allocated = pointer_in_eax(current_stream()->inline_buffer);
        flags = flags_in_cl(current_stream()->flags.bytes[1]);
        *(volatile unsigned *)&current_stream()->capacity = 1;
        /* Preserve the original ordering of the fallback buffer and flag writes. */
        flags = flags_in_cl(flags & 0xf8);
        *(void *volatile *)&current_stream()->buffer = allocated;
        direct_flags = flags_in_ch(flags);
        *(volatile unsigned char *)&current_stream()->flags.bytes[1] = flags;
        current_stream()->flags.bytes[1] = flags_in_ch(direct_flags | 4);
    } else {
        current_stream()->flags.bytes[0] |= 8;
    }
    allocated = pointer_in_eax(current_stream()->buffer);
    current_stream()->buffered = 0;
    current_stream()->next = allocated;
    return allocated;
}
