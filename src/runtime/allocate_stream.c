#include "rtstream.h"

enum { STREAM_RECORD_BYTES = 26, STREAM_OPEN = 3, STREAM_HEAP_OWNED = 0x4000 };

extern StreamLink *recycled_streams, *open_streams;
extern unsigned char static_streams[], static_streams_end[];
extern void *malloc(unsigned);
#pragma aux malloc modify exact [eax];
extern void *memset(void *, int, unsigned);
#pragma aux memset modify exact [eax edx ebx];
extern void set_errno(int);
#pragma aux set_errno modify exact [eax];

/* Keep the stream, link, and flags live in their original registers. */
extern unsigned word_in_edi(unsigned);
#pragma aux word_in_edi = "" parm [edi] value [edi] modify exact [];
extern unsigned flags_from_edi(void);
#pragma aux flags_from_edi = "" value [edi] modify exact [];
extern unsigned char *slot_in_ecx(unsigned char *);
#pragma aux slot_in_ecx = "" parm [ecx] value [ecx] modify exact [];
extern StreamLink *link_in_esi(StreamLink *);
#pragma aux link_in_esi = "" parm [esi] value [esi] modify exact [];
extern RuntimeStream *stream_in_ecx(RuntimeStream *);
#pragma aux stream_in_ecx = "" parm [ecx] value [ecx] modify exact [];

extern unsigned char *slot_from_ecx(void);
#pragma aux slot_from_ecx = "" value [ecx] modify exact [];
extern StreamLink *link_from_esi(void);
#pragma aux link_from_esi = "" value [esi] modify exact [];

/* Watcom widens the C OR to EDI. The original uses the 16-bit encoding. */
extern void enable_recycled_stream(void);
#pragma aux enable_recycled_stream = "or di,3" modify exact [];
extern unsigned malloc_size(void);
#pragma aux malloc_size = "" value [eax] modify exact [];
extern RuntimeStream *returned_stream(void);
#pragma aux returned_stream = "" value [ecx] modify exact [];

extern StreamLink *link_in_eax(StreamLink *);
#pragma aux link_in_eax = "" parm [eax] value [eax] modify exact [];
extern void before_flag_mask(unsigned, StreamLink *);
#pragma aux before_flag_mask = "" parm [edi] [eax] modify exact [];
extern void stage_heap_allocation(unsigned);
#pragma aux stage_heap_allocation = "" parm [eax] modify exact [edi];
extern void hold_previous_head(StreamLink *);
#pragma aux hold_previous_head = "" parm [eax] modify exact [edi];
extern StreamLink *head_from_eax(void);
#pragma aux head_from_eax = "" value [eax] modify exact [];

RuntimeStream *allocate_stream(void)
{
    StreamLink *link = link_in_esi(recycled_streams);

    if (link != 0) {
        stream_in_ecx(link_from_esi()->stream);
        {
            unsigned mode = word_in_edi(returned_stream()->flags.word);
            StreamLink *next = link_in_eax(link_from_esi()->next);
            before_flag_mask(mode, next);
            word_in_edi(mode & (STREAM_HEAP_OWNED | STREAM_OPEN));
            recycled_streams = next;
        }
        enable_recycled_stream();
        goto initialize;
    }

    for (slot_in_ecx(static_streams); (unsigned long)slot_from_ecx() < (unsigned long)static_streams_end;
         slot_in_ecx(slot_from_ecx() + STREAM_RECORD_BYTES)) {
        if (!(((volatile RuntimeStream *)slot_from_ecx())->flags.bytes[0] & STREAM_OPEN)) {
            link = link_in_esi(malloc(sizeof(StreamLink)));
            if (link == 0)
                goto fail;
            word_in_edi(STREAM_OPEN);
            goto initialize;
        }
    }

    stage_heap_allocation(sizeof(StreamLink) + STREAM_RECORD_BYTES);
    word_in_edi(STREAM_HEAP_OWNED | STREAM_OPEN);
    link = link_in_eax(malloc(malloc_size()));
    stream_in_ecx((RuntimeStream *)link);
    link_in_esi(link);
    if (link == 0)
        goto fail;
    stream_in_ecx((RuntimeStream *)(link + 1));

initialize:
    memset(returned_stream(), 0, STREAM_RECORD_BYTES);
    returned_stream()->flags.word = flags_from_edi();
    hold_previous_head(open_streams);
    link_from_esi()->stream = returned_stream();
    open_streams = link_from_esi();
    link_from_esi()->next = head_from_eax();
    return returned_stream();

fail:
    set_errno(5);
    return 0;
}
