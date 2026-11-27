#include "rtstream.h"

extern int set_errno(int);
#pragma aux set_errno modify exact [eax];
extern int flush_stream(RuntimeStream *);
#pragma aux flush_stream modify exact [eax];
extern long lseek(int, long, int);
#pragma aux lseek modify exact [eax edx ebx];
extern long tell(int);
#pragma aux tell modify exact [eax];
extern int seek_within_buffer(long, RuntimeStream *);
#pragma aux seek_within_buffer modify exact [eax edx];

/* Keep the original calling convention and register allocation. */
extern long offset_in_esi(long);
#pragma aux offset_in_esi = parm [esi] value [esi] modify exact [];
extern long current_offset(void);
#pragma aux current_offset = "" value [esi] modify exact [];
extern RuntimeStream *stream_in_edx(RuntimeStream *);
#pragma aux stream_in_edx = "" parm [edx] value [edx] modify exact [];
extern long offset_in_edi(long);
#pragma aux offset_in_edi = parm [edi] value [edi] modify exact [];
extern long offset_in_edx(long);
#pragma aux offset_in_edx = parm [edx] value [edx] modify exact [];
extern long position_in_eax(long);
#pragma aux position_in_eax = parm [eax] value [eax] modify exact [];
extern void *buffer_in_eax(void *);
#pragma aux buffer_in_eax = parm [eax] value [eax] modify exact [];
extern unsigned char flag_in_dl(unsigned char);
#pragma aux flag_in_dl = parm [dl] value [dl] modify exact [];
extern int descriptor_in_eax(int);
#pragma aux descriptor_in_eax = parm [eax] value [eax] modify exact [];
int fseek(RuntimeStream *, long, int);
#pragma aux fseek modify exact [eax ebx edx];
int fseek(RuntimeStream *stream, long offset, int origin)
{
    long wanted, status;
    int descriptor;
    unsigned char *buffer;
    unsigned char flags;
    RuntimeStream *seek_buffer;

    offset = offset_in_esi(offset);
    if (!(stream->flags.bytes[0] & 6))
        goto read_stream;
    /* Flush pending output before moving the underlying descriptor. */
    if (stream->flags.bytes[1] & 0x10) {
        if (!flush_stream(stream))
            goto seek_descriptor;
        if (origin || current_offset() >= 0)
            goto return_error;
invalid_seek:
        set_errno(9);
return_error:
        return -1;
    }

    if (origin == 1)
        offset = offset_in_esi(offset - stream->buffered);
    buffer = buffer_in_eax(stream->buffer);
    stream->buffered = 0;
    *(unsigned char *volatile *)&stream->next = buffer;
seek_descriptor:
    *(volatile unsigned char *)&stream->flags.bytes[0] &= 0xeb;
    status = lseek(stream->descriptor, current_offset(), origin);
    if (status != -1)
        goto success;
    return status;

read_stream:
    if ((unsigned)origin >= 1) {
        if ((unsigned)origin <= 1)
            goto seek_cur;
        if (origin == 2)
            goto seek_end;
        goto invalid_seek;
    }
    if (!origin)
        goto seek_set;
    goto invalid_seek;

seek_cur:
    /* A read-only stream can move within its existing buffer. */
    wanted = position_in_eax(offset_in_edx(offset));
    seek_buffer = stream_in_edx(stream);
    status = offset_in_edi(*(volatile long *)&stream->buffered);
    if (!seek_within_buffer(wanted, seek_buffer))
        goto success;
    wanted = offset_in_edx(offset);
    descriptor = descriptor_in_eax(stream->descriptor);
    wanted = offset_in_edx(wanted - status);
    status = lseek(descriptor, wanted, origin);
    if (status != -1)
        goto success;
    return status;

seek_set:
    status = position_in_eax(tell(stream->descriptor));
    wanted = offset_in_edx(stream->buffered);
    offset_in_edi(offset);
    status = position_in_eax(status - wanted);
    wanted = offset_in_edi(offset - status);
    if (!seek_within_buffer(wanted, stream))
        goto success;
    status = lseek(stream->descriptor, offset, origin);
    if (status != -1)
        goto success;
    return status;

seek_end:
    buffer = buffer_in_eax(stream->buffer);
    flags = flag_in_dl(stream->flags.bytes[0]);
    *(unsigned char *volatile *)&stream->next = buffer;
    flags = flag_in_dl(flags & 0xef);
    descriptor = descriptor_in_eax(stream->descriptor);
    stream->flags.bytes[0] = flags;
    wanted = offset_in_edx(offset);
    stream->buffered = 0;
    status = lseek(descriptor, wanted, origin);
    if (status == -1)
        return status;
success:
    return 0;
}
