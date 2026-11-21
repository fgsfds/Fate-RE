#include "rtstream.h"

extern unsigned char stderr_buffer_flags;
extern unsigned char static_streams[];
extern char allocation_error_message[];
extern StreamLink *open_streams;
extern StreamLink *recycled_streams;

extern void *allocate_memory(unsigned);
#pragma aux allocate_memory "malloc_" modify exact [eax];
extern void fatal_runtime_error(const char *, int);
#pragma aux fatal_runtime_error modify exact [eax edx];

/* Watcom register constraints for the original startup sequence. */
extern unsigned char byte_in_ah(unsigned char);
#pragma aux byte_in_ah = parm [ah] value [ah] modify exact [];
extern unsigned char byte_in_dl(unsigned char);
#pragma aux byte_in_dl = parm [dl] value [dl] modify exact [];
extern unsigned char *stream_in_ecx(unsigned char *);
#pragma aux stream_in_ecx = parm [ecx] value [ecx] modify exact [];
extern StreamLink *link_in_ebx(StreamLink *);
#pragma aux link_in_ebx = parm [ebx] value [ebx] modify exact [];
extern StreamLink *link_in_eax(StreamLink *);
#pragma aux link_in_eax = parm [eax] value [eax] modify exact [];
extern StreamLink *link_in_edx(StreamLink *);
#pragma aux link_in_edx = parm [edx] value [edx] modify exact [];

extern const char *message_in_eax(const char *);
#pragma aux message_in_eax = parm [eax] value [eax] modify exact [];

extern void release_accumulator(void);
#pragma aux release_accumulator = "" modify exact [eax];
void initialize_standard_streams(void);
#pragma aux initialize_standard_streams modify exact [eax];
void initialize_standard_streams(void)
{
    unsigned char *next;
    StreamLink *link;
    unsigned char flags = byte_in_ah(stderr_buffer_flags), unbuffered;
    StreamLink *occupied;
    unsigned long stream_flags;

    /* Keep standard error unbuffered. */
    flags = byte_in_ah(flags & 0xf8);
    unbuffered = byte_in_dl(flags);
    *(volatile unsigned char *)&stderr_buffer_flags = flags;
    unbuffered = byte_in_dl(unbuffered | 4);
    next = stream_in_ecx(static_streams);
    stderr_buffer_flags = unbuffered;
    goto check_stream;

allocate_node:
    link = link_in_eax(allocate_memory(sizeof(StreamLink)));
    link = link_in_ebx(link);
    if (!link) {
        /* The runtime retries the allocation before reporting a fatal error. */
        link = link_in_eax(allocate_memory(sizeof(StreamLink)));
        link = link_in_ebx(link);
        if (!link)
            fatal_runtime_error(message_in_eax(allocation_error_message), 1);
    }
    occupied = link_in_edx(open_streams);
    link->stream = (RuntimeStream *)next;
    *(StreamLink *volatile *)&open_streams = link;
    /* The static stream table uses 26-byte records. */
    next = stream_in_ecx(next + 26);
    link->next = occupied;

check_stream:
    stream_flags = ((volatile RuntimeStream *)next)->flags.word;
    release_accumulator();
    if (stream_flags)
        goto allocate_node;
    /* The zero-flags sentinel also supplies the empty recycled list value. */
    recycled_streams = (StreamLink *)stream_flags;
}
