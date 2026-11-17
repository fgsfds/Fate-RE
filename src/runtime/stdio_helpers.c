#include "rtstream.h"

int toupper(int ch)
{
    if (ch >= 'a' && ch <= 'z')
        ch -= 'a' - 'A';
    return ch;
}

int hex_digit(int digit)
{
    digit += '0';
    if (digit > '9')
        digit += 'a' - '9' - 1;
    return digit;
}

extern RuntimeStream *open_shared_file(const char *, const char *, int);
#pragma aux open_shared_file "_fsopen_" modify exact [eax edx ebx];
RuntimeStream *fopen(const char *filename, const char *mode)
{
    return open_shared_file(filename, mode, 0);
}

/* The close entry transfers directly to the descriptor implementation. */
extern int close_descriptor(int);
#pragma aux close_descriptor aborts modify exact [eax];
int close_transfer(int handle);
#pragma aux close_transfer "close_";
int close_transfer(int handle)
{
    return close_descriptor(handle);
}

extern StreamLink *open_streams;
extern int flush_stream(RuntimeStream *);
#pragma aux flush_stream modify exact [eax];

int flush_matching_streams(unsigned long mask);

/* Place this wrapper first so Watcom falls through to the shared body. */
int flushall(void)
{
    return flush_matching_streams(~0UL);
}

int flush_matching_streams(unsigned long mask)
{
    StreamLink *link = open_streams;
    int count = 0;
    goto check_link;
    do {
        RuntimeStream *stream = link->stream;
        if (stream->flags.word & mask) {
            ++count;
            if (stream->flags.bytes[1] & 0x10)
                flush_stream(stream);
        }
        link = link->next;
check_link:
        ;
    } while (link);
    return count;
}

extern RuntimeStream *allocate_stream(int);
#pragma aux allocate_stream modify exact [eax];
extern RuntimeStream *__doopen(const char *, const char *, int, RuntimeStream *);
#pragma aux __doopen modify exact [eax edx ebx ecx];
extern RuntimeStream *close_file(RuntimeStream *);
#pragma aux close_file modify exact [eax];

/* Keep the allocated stream in ECX before testing the original EAX result. */
extern RuntimeStream *keep_open_stream(RuntimeStream *);
#pragma aux keep_open_stream = parm [ecx] value [ecx] modify exact [];

RuntimeStream *_fsopen(const char *name, const char *mode, int share)
{
    RuntimeStream *opened = allocate_stream(0);
    RuntimeStream *stream = keep_open_stream(opened);
    if (opened)
        return __doopen(name, mode, share, stream);
    return opened;
}

RuntimeStream *freopen(const char *name, const char *mode, RuntimeStream *stream)
{
    RuntimeStream *opened = close_file(stream);
    stream = keep_open_stream(opened);
    if (opened) {
        *(volatile unsigned long *)&opened->flags.word &= 0x4000;
        return __doopen(name, mode, 0, stream);
    }
    return opened;
}

extern int __doclose(RuntimeStream *, int);
#pragma aux __doclose modify exact [eax edx];
extern void free_stream(RuntimeStream *);
#pragma aux free_stream modify exact [eax];
extern int close_result_in_edx(int);
#pragma aux close_result_in_edx = parm [edx] value [edx] modify exact [];
int __shutdown_stream(RuntimeStream *, int);
#pragma aux __shutdown_stream modify exact [eax edx];
int __shutdown_stream(RuntimeStream *stream, int mode)
{
    int status = close_result_in_edx(__doclose(stream, mode));
    free_stream(stream);
    return status;
}

extern int shutdown_open_stream(int, RuntimeStream *);
#pragma aux shutdown_open_stream "__shutdown_stream_" parm [edx] [eax] modify exact [eax edx];
extern RuntimeStream *match_stream_in_edx(RuntimeStream *);
#pragma aux match_stream_in_edx = parm [edx] value [edx] modify exact [];
extern RuntimeStream *read_candidate_in_ebx(RuntimeStream *);
#pragma aux read_candidate_in_ebx = parm [ebx] value [ebx] modify exact [];
int fclose(RuntimeStream *);
#pragma aux fclose modify exact [eax];
int fclose(RuntimeStream *stream)
{
    StreamLink *link, *next;
    RuntimeStream *candidate;
    RuntimeStream *match = match_stream_in_edx(stream);
    link = open_streams;
    for (;;) {
        if (!link)
            return -1;
        candidate = read_candidate_in_ebx(link->stream);
        if (match == candidate)
            break;
        link = link->next;
    }
    return shutdown_open_stream(1, candidate);
}

extern StreamLink *recycled_streams;
extern void free(void *);
#pragma aux free modify exact [eax];
extern StreamLink *hold_link_in_edx(StreamLink *);
#pragma aux hold_link_in_edx = parm [edx] value [edx] modify exact [];
extern StreamLink *hold_link_in_eax(StreamLink *);
#pragma aux hold_link_in_eax = parm [eax] value [eax] modify exact [];
extern StreamLink *hold_next_in_ebx(StreamLink *);
#pragma aux hold_next_in_ebx = parm [ebx] value [ebx] modify exact [];
void free_recycled_streams(void);
#pragma aux free_recycled_streams modify exact [eax];
void free_recycled_streams(void)
{
    StreamLink *link, *next, *allocation;
    while (link = hold_link_in_edx(recycled_streams)) {
        allocation = hold_link_in_eax(link);
        next = hold_link_in_edx(link->next);
        free(allocation);
        recycled_streams = next;
    }
}

extern RuntimeStream *hold_stream_in_ebx(RuntimeStream *);
#pragma aux hold_stream_in_ebx = parm [ebx] value [ebx] modify exact [];
extern StreamLink **hold_link_slot(StreamLink **);
#pragma aux hold_link_slot = parm [edx] value [edx] modify exact [];
extern RuntimeStream *hold_matching_stream(RuntimeStream *);
#pragma aux hold_matching_stream = parm [ecx] value [ecx] modify exact [];
void recycle_stream(RuntimeStream *);
#pragma aux recycle_stream modify exact [eax];
void recycle_stream(RuntimeStream *stream)
{
    RuntimeStream *wanted = hold_stream_in_ebx(stream);
    StreamLink **slot = hold_link_slot(&open_streams);
    StreamLink *link, *next;
    RuntimeStream *candidate;
scan:
    link = hold_link_in_eax(*slot);
    if (!link)
        goto done;
    candidate = hold_matching_stream(link->stream);
    if (wanted == candidate)
        goto matched;
    slot = hold_link_slot(&link->next);
    goto scan;

matched:
    candidate = hold_matching_stream(candidate);
    wanted->flags.bytes[0] = candidate->flags.bytes[0] | 3;
    *slot = hold_next_in_ebx(link->next);
    next = hold_link_in_edx(recycled_streams);
    recycled_streams = link;
    link->next = next;
done:
    return;
}

extern int (*stream_hook)(void);
int call_stream_hook(void)
{
    return stream_hook();
}

extern int fill_buffer(RuntimeStream *);
#pragma aux fill_buffer modify exact [eax];
extern long buffered_in_ebx(long);
#pragma aux buffered_in_ebx = parm [ebx] value [ebx] modify exact [];
extern unsigned char *cursor_in_ecx(unsigned char *);
#pragma aux cursor_in_ecx = parm [ecx] value [ecx] modify exact [];
extern unsigned value_from_al(unsigned char);
#pragma aux value_from_al = parm [al] value [eax] modify exact [];
int refill_and_get_character(RuntimeStream *);
#pragma aux refill_and_get_character modify exact [eax];
int refill_and_get_character(RuntimeStream *stream)
{
    RuntimeStream *saved = match_stream_in_edx(stream);
    long count;
    unsigned char *next;
    if (!fill_buffer(stream))
        return -1;
    count = buffered_in_ebx(saved->buffered);
    next = cursor_in_ecx(saved->next);
    count = buffered_in_ebx(count - 1);
    next = cursor_in_ecx(next + 1);
    saved->buffered = count;
    saved->next = next;
    return value_from_al(next[-1]) & 0xff;
}

extern long tell(int);
#pragma aux tell modify exact [eax];
extern long position_in_ebx(long);
#pragma aux position_in_ebx = parm [ebx] value [ebx] modify exact [];
extern long count_in_ecx(long);
#pragma aux count_in_ecx = parm [ecx] value [ecx] modify exact [];
long ftell(RuntimeStream *);
#pragma aux ftell modify exact [eax];
long ftell(RuntimeStream *stream)
{
    RuntimeStream *saved = match_stream_in_edx(stream);
    long position = tell(stream->descriptor);
    long original = position_in_ebx(position);
    long buffered;
    if (position == -1)
        return position;
    buffered = count_in_ecx(saved->buffered);
    if (!buffered)
        return position;
    if ((saved->flags.bytes[1] & 0x10) != 0)
        return buffered + original;
    return original - buffered;
}

extern int isatty(int);
#pragma aux isatty modify exact [eax];
extern unsigned char flags_in_bl(unsigned char);
#pragma aux flags_in_bl = parm [bl] value [bl] modify exact [];
extern unsigned char flags_in_cl(unsigned char);
#pragma aux flags_in_cl = parm [cl] value [cl] modify exact [];
/* The descriptor is read through the saved stream pointer in EDX. */
extern void release_eax_for_descriptor(void);
#pragma aux release_eax_for_descriptor = modify exact [eax];
void detect_terminal(RuntimeStream *);
#pragma aux detect_terminal modify exact [eax];
void detect_terminal(RuntimeStream *stream)
{
    RuntimeStream *saved = match_stream_in_edx(stream);
    unsigned char flags;
    if (stream->flags.bytes[1] & 0x20)
        return;
    release_eax_for_descriptor();
    if (!isatty(saved->descriptor))
        return;
    flags = flags_in_bl(saved->flags.bytes[1]);
    flags = flags_in_bl(flags | 0x20);
    saved->flags.bytes[1] = flags;
    if (!(flags & 7))
        saved->flags.bytes[1] = flags_in_cl(flags) | 2;
}
