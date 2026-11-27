#include "rtstream.h"

extern int set_errno(int);
#pragma aux set_errno modify exact [eax];
extern int refill_and_get_character(RuntimeStream *);
#pragma aux refill_and_get_character modify exact [eax];

/* Register constraints for the two inlined buffer reads and the flag updates. */
extern long count_in_ebx(long);
#pragma aux count_in_ebx = parm [ebx] value [ebx] modify exact [];
extern long count_in_esi(long);
#pragma aux count_in_esi = parm [esi] value [esi] modify exact [];
extern unsigned char *next_in_ebx(unsigned char *);
#pragma aux next_in_ebx = parm [ebx] value [ebx] modify exact [];
extern unsigned byte_in_eax(unsigned char);
#pragma aux byte_in_eax = parm [al] value [eax] modify exact [];
extern int result_in_eax(int);
#pragma aux result_in_eax = parm [eax] value [eax] modify exact [];
extern unsigned char low_flag_in_bl(unsigned char);
#pragma aux low_flag_in_bl = parm [bl] value [bl] modify exact [];
extern unsigned char low_flag_in_cl(unsigned char);
#pragma aux low_flag_in_cl = parm [cl] value [cl] modify exact [];

#define READ_CHARACTER(keep_count) \
    do { \
        long count = keep_count(stream->buffered); \
        count = keep_count(count - 1); \
        stream->buffered = count; \
        if (count < 0) { \
            character = refill_and_get_character(stream); \
        } else { \
            unsigned char *next = next_in_ebx(stream->next); \
            unsigned byte = byte_in_eax(*next); \
            next = next_in_ebx(next + 1); \
            character = result_in_eax(byte & 0xff); \
            stream->next = next; \
        } \
    } while (0)

/* Let Watcom reuse the argument register once the access check is done. */
extern void release_incoming_register(void);
#pragma aux release_incoming_register = modify exact [eax];

int fgetc(RuntimeStream *);
#pragma aux fgetc modify exact [eax];
int fgetc(RuntimeStream *stream)
{
    int character;

    if (!(*(const volatile unsigned char *)&stream->flags.bytes[0] & 1)) {
        unsigned char flags;
        set_errno(4);
        release_incoming_register();
        flags = low_flag_in_bl(stream->flags.bytes[0]);
        flags = low_flag_in_bl(flags | 0x20);
        character = result_in_eax(-1);
        stream->flags.bytes[0] = flags;
    } else {
        release_incoming_register();
        READ_CHARACTER(count_in_ebx);
    }
    /* Text streams consume a following byte after CR and treat Ctrl-Z as EOF. */
    if (!(stream->flags.bytes[0] & 0x40)) {
        if (character == 13)
            READ_CHARACTER(count_in_esi);
        if (character == 26) {
            unsigned char flags = low_flag_in_cl(stream->flags.bytes[0]);
            flags = low_flag_in_cl(flags | 0x10);
            character = result_in_eax(-1);
            stream->flags.bytes[0] = flags;
        }
    }
    return character;
}
