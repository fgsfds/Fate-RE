#include "rtstream.h"

extern StreamLink *open_streams, *recycled_streams;
extern int close_stream(RuntimeStream *, int);
#pragma aux close_stream modify exact [eax edx];
extern int set_errno(int);
#pragma aux set_errno modify exact [eax];
/* Preserve the original stream pointer while walking either list. */
extern void save_stream(RuntimeStream *);
#pragma aux save_stream = parm [ebx] modify exact [];
extern RuntimeStream *saved_stream(void);
#pragma aux saved_stream = value [ebx] modify exact [];
extern RuntimeStream *target_in_edx(RuntimeStream *);
#pragma aux target_in_edx = parm [edx] value [edx] modify exact [];
extern StreamLink *link_in_eax(StreamLink *);
#pragma aux link_in_eax = parm [eax] value [eax] modify exact [];
extern StreamLink **slot_in_edx(StreamLink **);
#pragma aux slot_in_edx = parm [edx] value [edx] modify exact [];
extern StreamLink *link_in_ecx(StreamLink *);
#pragma aux link_in_ecx = parm [ecx] value [ecx] modify exact [];
extern StreamLink *link_in_edx(StreamLink *);
#pragma aux link_in_edx = parm [edx] value [edx] modify exact [];

extern RuntimeStream *matched_stream(void);
#pragma aux matched_stream = value [edx] modify exact [];
extern RuntimeStream *close_target_in_eax(RuntimeStream *);
#pragma aux close_target_in_eax = parm [eax] value [eax] modify exact [];

RuntimeStream *close_file(RuntimeStream *);
#pragma aux close_file modify exact [eax];
RuntimeStream *close_file(RuntimeStream *stream)
{
    StreamLink *link, *next;
    StreamLink **slot;
    RuntimeStream *candidate;

    save_stream(stream);
    link = link_in_eax(open_streams);
scan_open:
    if (!link)
        goto scan_recycled;
    candidate = target_in_edx(link->stream);
    if (saved_stream() != candidate)
        goto next_open;
    if (candidate->flags.bytes[0] & 3)
        close_stream(close_target_in_eax(matched_stream()), 1);
reusable:
    return saved_stream();
next_open:
    link = link_in_eax(link->next);
    goto scan_open;

scan_recycled:
    slot = slot_in_edx(&recycled_streams);
read_recycled:
    link = link_in_eax(*slot);
    if (!link)
        goto bad_stream;
    if (saved_stream() != link->stream)
        goto next_recycled;
    next = link_in_ecx(link->next);
    *slot = next;
    next = link_in_edx(open_streams);
    open_streams = link;
    link->next = next;
    goto reusable;
next_recycled:
    slot = slot_in_edx(&link->next);
    goto read_recycled;
bad_stream:
    set_errno(4);
    return 0;
}
