#include "rtstream.h"

extern unsigned char *cursor_in_ecx(unsigned char *);
#pragma aux cursor_in_ecx = parm [ecx] value [ecx] modify exact [];
extern unsigned char *base_in_ebx(unsigned char *);
#pragma aux base_in_ebx = parm [ebx] value [ebx] modify exact [];
extern long difference_in_ebx(long);
#pragma aux difference_in_ebx = parm [ebx] value [ebx] modify exact [];
extern long count_in_edi(long);
#pragma aux count_in_edi = parm [edi] value [edi] modify exact [];
extern unsigned char *cursor_in_esi(unsigned char *);
#pragma aux cursor_in_esi = parm [esi] value [esi] modify exact [];
extern int success_in_eax(int);
#pragma aux success_in_eax = parm [eax] value [eax] modify exact [];
int seek_within_buffer(long, RuntimeStream *);
#pragma aux seek_within_buffer modify exact [eax edx];
int seek_within_buffer(long offset, RuntimeStream *stream)
{
    unsigned char *cursor;
    long difference;
    unsigned char *base;
    long count;
    int result;
    stream->flags.bytes[0] &= ~0x10;
    if (offset > stream->buffered)
        goto clear_buffer;
    base = base_in_ebx(stream->buffer);
    cursor = cursor_in_ecx(stream->next);
    difference = difference_in_ebx(base - cursor);
    if (offset < difference)
        goto clear_buffer;
    count = count_in_edi(stream->buffered);
    cursor = cursor_in_esi(cursor + offset);
    count -= offset;
    stream->next = cursor;
    result = success_in_eax(0);
    stream->buffered = count;
    return result;

clear_buffer:
    cursor = stream->buffer;
    stream->buffered = 0;
    stream->next = cursor;
    return 1;
}
