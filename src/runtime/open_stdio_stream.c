#include "rtstream.h"

extern unsigned long __open_flags(const char *);
#pragma aux __open_flags modify exact [eax];
extern unsigned char lowercase_mode(int);
#pragma aux lowercase_mode "tolower_" value [al] modify exact [eax];
extern int sopen(const char *, int, int, ...);
#pragma aux sopen parm caller [] modify exact [eax];
extern void free_stream(RuntimeStream *);
#pragma aux free_stream modify exact [eax];
extern int fseek(RuntimeStream *, long, int);
#pragma aux fseek modify exact [eax ebx edx];
extern void detect_terminal(RuntimeStream *);
#pragma aux detect_terminal modify exact [eax];

/* Watcom register constraints for the original descriptor open sequence. */
extern const char *path_in_esi(const char *);
#pragma aux path_in_esi = parm [esi] value [esi] modify exact [];
extern unsigned word_in_edi(unsigned);
#pragma aux word_in_edi = parm [edi] value [edi] modify exact [];
extern int result_in_eax(int);
#pragma aux result_in_eax = parm [eax] value [eax] modify exact [];
extern unsigned byte_from_al(unsigned char);
#pragma aux byte_from_al = parm [al] value [eax] modify exact [];
extern unsigned char mode_in_dl(unsigned char);
#pragma aux mode_in_dl = parm [dl] value [dl] modify exact [];
extern unsigned char flags_in_dh(unsigned char);
#pragma aux flags_in_dh = parm [dh] value [dh] modify exact [];

RuntimeStream *__doopen(const char *, const char *, int, RuntimeStream *);
#pragma aux __doopen modify exact [eax ebx edx ecx];
RuntimeStream *__doopen(const char *path, const char *mode, int sharing, RuntimeStream *stream)
{
    unsigned flags;
    int access;
    unsigned char ch, saved_ch;

    path = path_in_esi(path);
    *(volatile unsigned char *)&stream->flags.bytes[0] &= 0xfc;
    access = __open_flags(mode);
    flags = word_in_edi(stream->flags.word);
    flags = word_in_edi(flags | access);
    access = result_in_eax(0);
    stream->flags.word = flags;
    ch = lowercase_mode(byte_from_al((unsigned char)*mode));
    saved_ch = mode_in_dl(ch);

    /* Read modes open an existing file. Write modes can create it. */
    if (ch == 'r') {
        unsigned char low_flags = flags_in_dh(stream->flags.bytes[0]);
        access = result_in_eax(0);
        if (low_flags & 2)
            access = result_in_eax(2);
        if (stream->flags.bytes[0] & 0x40)
            access |= 0x200;
        else
            access |= 0x100;
        stream->descriptor = sopen(path, access, sharing, 0);
    } else {
        access = result_in_eax((stream->flags.bytes[0] & 1) != 0);
        access = result_in_eax(access + 0x21);
        if (saved_ch == 'a')
            access |= 0x10;
        else
            access |= 0x40;
        if (stream->flags.bytes[0] & 0x40)
            access |= 0x200;
        else
            access |= 0x100;
        stream->descriptor = sopen(path, access, sharing, 0x180);
    }
    /* The original code checks the descriptor after storing it. */
    if (*(volatile int *)&stream->descriptor == -1) {
        free_stream(stream);
        return 0;
    }
    stream->buffered = 0;
    stream->buffer = 0;
    stream->capacity = 0;
    if (saved_ch == 'a')
        fseek(stream, 0, 2);
    detect_terminal(stream);
    return stream;
}
