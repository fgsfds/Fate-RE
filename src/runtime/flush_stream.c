#include "rtstream.h"

extern int set_errno(int);
#pragma aux set_errno modify exact [eax];
extern long write_stream_descriptor(int, const void *, unsigned);
#pragma aux write_stream_descriptor modify exact [eax ebx edx];
extern long lseek(int, long, int);
#pragma aux lseek modify exact [eax edx ebx];

/* Preserve Watcom register allocation without emitting extra instructions. */
extern long result_in_esi(long);
#pragma aux result_in_esi = parm [esi] value [esi] modify exact [];
extern long result_in_eax(long);
#pragma aux result_in_eax = parm [eax] value [eax] modify exact [];
extern long current_eax(void);
#pragma aux current_eax = "" value [eax] modify exact [];
extern long offset_in_edx(long);
#pragma aux offset_in_edx = parm [edx] value [edx] modify exact [];
extern int origin_in_ebx(int);
#pragma aux origin_in_ebx = parm [ebx] value [ebx] modify exact [];
extern void *buffer_in_eax(void *);
#pragma aux buffer_in_eax = parm [eax] value [eax] modify exact [];

extern unsigned char in_ah(unsigned char);
#pragma aux in_ah = parm [ah] value [ah] modify exact [];
extern unsigned char in_al(unsigned char);
#pragma aux in_al = parm [al] value [al] modify exact [];
extern unsigned char in_bh(unsigned char);
#pragma aux in_bh = parm [bh] value [bh] modify exact [];
extern unsigned char in_bl(unsigned char);
#pragma aux in_bl = parm [bl] value [bl] modify exact [];
extern unsigned char in_dh(unsigned char);
#pragma aux in_dh = parm [dh] value [dh] modify exact [];
extern unsigned char in_dl(unsigned char);
#pragma aux in_dl = parm [dl] value [dl] modify exact [];

int flush_stream(RuntimeStream *);
#pragma aux flush_stream modify exact [eax];
int flush_stream(RuntimeStream *stream)
{
    long result, status;
    unsigned char mode, flags;
    void *buffer;

    mode = in_ah(stream->flags.bytes[1]);
    result = result_in_esi(0);
    if (mode & 0x10) {
        /* Write pending output and report short writes as stream errors. */
        mode = in_bh(stream->flags.bytes[1]);
        mode = in_bh(mode & ~0x10);
        flags = in_al(stream->flags.bytes[0]);
        stream->flags.bytes[1] = mode;
        if (!(flags & 2))
            goto reset;
        if (!stream->buffer)
            goto reset;
        status = write_stream_descriptor(stream->descriptor, stream->buffer,
                                         stream->buffered);
        if (status == -1) {
            flags = in_dl(stream->flags.bytes[0]);
            flags = in_dl(flags | 0x20);
            result = result_in_esi(status);
            stream->flags.bytes[0] = flags;
            goto reset;
        }
        if (status == stream->buffered)
            goto reset;
        set_errno(12);
        flags = in_ah(stream->flags.bytes[0]);
        flags = in_ah(flags | 0x20);
        result = result_in_esi(-1);
        stream->flags.bytes[0] = flags;
    } else {
        /* Rewind past unread bytes unless the descriptor is a device. */
        if (!stream->buffer)
            goto reset;
        flags = in_dl(stream->flags.bytes[0]);
        flags = in_dl(flags & ~0x10);
        mode = in_dh(stream->flags.bytes[1]);
        stream->flags.bytes[0] = flags;
        if (mode & 0x20)
            goto reset;
        status = result_in_eax(stream->buffered);
        if (status) {
            long offset;
            int origin;
            offset = offset_in_edx(current_eax());
            origin = origin_in_ebx(1);
            offset = offset_in_edx(-offset);
            status = lseek(stream->descriptor, offset, origin);
        }
        /* EAX holds either zero unread bytes or the seek result. */
        status = current_eax();
        if (status != -1)
            goto reset;
        flags = in_bl(stream->flags.bytes[0]);
        flags = in_bl(flags | 0x20);
        result = result_in_esi(status);
        stream->flags.bytes[0] = flags;
    }
reset:
    buffer = buffer_in_eax(stream->buffer);
    stream->buffered = 0;
    stream->next = buffer;
    return result;
}
