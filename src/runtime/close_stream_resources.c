#include "rtstream.h"

extern int flush_stream(RuntimeStream *);
#pragma aux flush_stream modify exact [eax];
extern long ftell(RuntimeStream *);
#pragma aux ftell modify exact [eax];
extern long lseek(int, long, int);
#pragma aux lseek modify exact [eax edx ebx];
extern int close_stream_descriptor(int);
#pragma aux close_stream_descriptor modify exact [eax];
extern void free(void *);
#pragma aux free modify exact [eax];
extern void __MkTmpFile(char *, unsigned);
#pragma aux __MkTmpFile modify exact [eax edx];
extern int remove(const char *);
#pragma aux remove modify exact [eax];

/* ECX keeps the stream pointer across the DOS and stdio calls. */
extern void save_stream(RuntimeStream *);
#pragma aux save_stream = parm [ecx] modify exact [];
extern RuntimeStream *saved_stream(void);
#pragma aux saved_stream = value [ecx] modify exact [];
extern RuntimeStream *incoming_stream(void);
#pragma aux incoming_stream = value [eax] modify exact [];
extern void save_close_mode(int);
#pragma aux save_close_mode = parm [edi] modify exact [];
extern int close_mode(void);
#pragma aux close_mode = value [edi] modify exact [];
extern int close_status(int);
#pragma aux close_status = parm [esi] value [esi] modify exact [];
extern unsigned char flags_in_ah(unsigned char);
#pragma aux flags_in_ah = parm [ah] value [ah] modify exact [];
extern long position_in_edx(long);
#pragma aux position_in_edx = parm [edx] value [edx] modify exact [];
extern unsigned char suffix_in_dl(unsigned char);
#pragma aux suffix_in_dl = parm [dl] value [dl] modify exact [];
extern unsigned suffix_value(unsigned char);
#pragma aux suffix_value = parm [dl] value [edx] modify exact [];
extern unsigned value_in_edx(unsigned);
#pragma aux value_in_edx = parm [edx] value [edx] modify exact [];
extern char *path_in_eax(char *);
#pragma aux path_in_eax = parm [eax] value [eax] modify exact [];

int __doclose(RuntimeStream *, int);
#pragma aux __doclose modify exact [eax edx];
int __doclose(RuntimeStream *stream, int mode)
{
    char temporary_name[16];
    long position, saved_position;
    int status;
    unsigned char flags;

    save_stream(stream);
    save_close_mode(mode);
    if (!incoming_stream()->flags.word) {
        status = close_status(-1);
        goto done;
    }
    flags = flags_in_ah(incoming_stream()->flags.bytes[1]);
    status = close_status(0);
    if (flags & 0x10)
        status = close_status(flush_stream(saved_stream()));
    position = ftell(saved_stream());
    saved_position = position_in_edx(position);
    if (position != -1)
        lseek(saved_stream()->descriptor, saved_position, 0);
    if (close_mode())
        status = close_status(status | close_stream_descriptor(saved_stream()->descriptor));
    if (saved_stream()->flags.bytes[0] & 8) {
        free(saved_stream()->buffer);
        saved_stream()->buffer = 0;
    }
    if (saved_stream()->flags.bytes[1] & 8) {
        unsigned suffix = value_in_edx(0);
        char *path = path_in_eax(temporary_name);
        suffix = suffix_value(suffix_in_dl(saved_stream()->inline_buffer[1]));
        __MkTmpFile(path, suffix);
        remove(temporary_name);
    }
done:
    return status;
}
