#include "rtstream.h"

extern unsigned char static_streams[], standard_streams_end[];
extern StreamLink *open_streams;
extern int __shutdown_stream(RuntimeStream *, int);
#pragma aux __shutdown_stream modify exact [eax];

/* Watcom register constraints for traversal across __shutdown_stream. */
extern unsigned index_in_edx(unsigned);
#pragma aux index_in_edx = parm [edx] value [edx] modify exact [];
extern unsigned offset_in_eax(unsigned);
#pragma aux offset_in_eax = parm [eax] value [eax] modify exact [];
extern unsigned char *limit_in_esi(unsigned char *);
#pragma aux limit_in_esi = parm [esi] value [esi] modify exact [];
extern unsigned count_in_ebx(unsigned);
#pragma aux count_in_ebx = parm [ebx] value [ebx] modify exact [];
extern unsigned count_value(void);
#pragma aux count_value = "" value [ebx] modify exact [];
extern StreamLink *link_in_eax(StreamLink *);
#pragma aux link_in_eax = parm [eax] value [eax] modify exact [];
extern StreamLink *next_in_ecx(StreamLink *);
#pragma aux next_in_ecx = parm [ecx] value [ecx] modify exact [];
extern RuntimeStream *stream_in_eax(RuntimeStream *);
#pragma aux stream_in_eax = parm [eax] value [eax] modify exact [];
extern RuntimeStream *saved_stream(void);
#pragma aux saved_stream = "" value [eax] modify exact [];
extern int close_in_edx(int);
#pragma aux close_in_edx = parm [edx] value [edx] modify exact [];

unsigned close_streams_from_index(unsigned);
#pragma aux close_streams_from_index modify exact [eax];
/* The first five records are the CRT standard streams. */
unsigned close_nonstandard_streams(void)
{
    return close_streams_from_index(5);
}

unsigned close_streams_from_index(unsigned index)
{
    StreamLink *link;
    unsigned offset;
    unsigned char *limit;

    /* Compute the byte offset for a packed 26-byte stream record. */
    index = index_in_edx(index);
    offset = offset_in_eax(index * 4);
    offset = offset_in_eax(offset - index);
    offset = offset_in_eax(offset * 4);
    offset = offset_in_eax(offset + index);
    limit = limit_in_esi(static_streams);
    offset = offset_in_eax(offset * 2);
    count_in_ebx(0);
    limit = limit_in_esi(limit + offset);
    link = link_in_eax(open_streams);
    goto check_node;

    do {
        int close_descriptor;
        /* Closing this stream can remove its link from the open list. */
        StreamLink *next = next_in_ecx(link->next);
        stream_in_eax(link->stream);
        close_descriptor = close_in_edx(1);
        if (!(saved_stream()->flags.bytes[1] & 0x40)) {
            if ((unsigned char *)saved_stream() < limit)
                goto next_stream;
            if ((unsigned char *)saved_stream() < standard_streams_end)
                close_descriptor = close_in_edx(0);
        }
        __shutdown_stream(saved_stream(), close_descriptor);
        count_in_ebx(count_value() + 1);
next_stream:
        link = link_in_eax(next);
check_node:
        ;
    } while (link);
    return count_value();
}
