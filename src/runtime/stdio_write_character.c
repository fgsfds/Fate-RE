#include "rtstream.h"

extern int set_errno(int);
#pragma aux set_errno modify exact [eax];
extern unsigned char *allocate_stream_buffer(RuntimeStream *);
#pragma aux allocate_stream_buffer modify exact [eax];
extern int flush_stream(RuntimeStream *);
#pragma aux flush_stream modify exact [eax];

/* These register constraints emit no code. */
extern unsigned mask_in_ecx(unsigned);
#pragma aux mask_in_ecx = parm [ecx] value [ecx] modify exact [];
extern unsigned char flags_in_al(unsigned char);
#pragma aux flags_in_al = parm [al] value [al] modify exact [];
extern unsigned value_in_edi(unsigned);
#pragma aux value_in_edi = parm [edi] value [edi] modify exact [];
extern int pending_character(void);
#pragma aux pending_character = value [ebx] modify exact [];
extern long count_in_esi(long);
#pragma aux count_in_esi = parm [esi] value [esi] modify exact [];
extern unsigned char *next_in_esi(unsigned char *);
#pragma aux next_in_esi = parm [esi] value [esi] modify exact [];
extern unsigned char *next_in_eax(unsigned char *);
#pragma aux next_in_eax = parm [eax] value [eax] modify exact [];

/* The original keeps the character in EBX and the CR-path capacity in EBP.
 * Save EBP explicitly because this Watcom release rejects an EBP clobber
 * in an inline pragma. Both write paths reach the matching restore.
 */
extern void enter_character_write(int);
#pragma aux enter_character_write = "push ebp" "mov ebx, eax" parm [eax] modify exact [ebx];
extern void restore_capacity_register(void);
#pragma aux restore_capacity_register = "pop ebp" modify exact [];
/* EDX still holds the stream. */
extern unsigned get_cr_capacity(void);
#pragma aux get_cr_capacity = "mov ebp, dword ptr [edx+14h]" parm [] value [ebp] modify exact [];

int fputc(int, RuntimeStream *);
#pragma aux fputc modify exact [eax edx];
int fputc(int character, RuntimeStream *stream)
{
    unsigned flush_mask;
    long count;
    int result;

    enter_character_write(character);
    if (!(stream->flags.bytes[0] & 2)) {
        set_errno(4);
        stream->flags.bytes[0] |= 0x20;
write_error:
        result = -1;
        goto done;
    }
    if (stream->buffer == 0)
        allocate_stream_buffer(stream);

    flush_mask = mask_in_ecx(0x400);
    /* Text streams expand LF to CRLF. The inserted CR may fill the buffer. */
    if (pending_character() == 10) {
        unsigned char flags = flags_in_al(stream->flags.bytes[0]);
        flush_mask = mask_in_ecx(0x600);
        if (!(flags & 0x40)) {
            unsigned char *next;
            unsigned capacity;
            *(volatile unsigned char *)&stream->flags.bytes[1] |= 0x10;
            *stream->next = 13;
            next = next_in_esi(*(unsigned char *volatile *)&stream->next);
            next = next_in_esi(next + 1);
            count = (long)value_in_edi(stream->buffered);
            *(unsigned char *volatile *)&stream->next = next;
            count = (long)value_in_edi(count + 1);
            capacity = get_cr_capacity();
            stream->buffered = count;
            if (count == capacity && flush_stream(stream) != 0)
                goto write_error;
        }
    }

    *(volatile unsigned char *)&stream->flags.bytes[1] |= 0x10;
    *stream->next = (unsigned char)pending_character();
    {
        unsigned char *next = next_in_eax(*(unsigned char *volatile *)&stream->next);
        unsigned flags;
        next = next_in_eax(next + 1);
        count = count_in_esi(stream->buffered);
        *(unsigned char *volatile *)&stream->next = next;
        count = count_in_esi(count + 1);
        flags = value_in_edi(stream->flags.word);
        stream->buffered = count;
        if ((flush_mask & flags) || count == stream->capacity) {
            if (flush_stream(stream) != 0)
                goto write_error;
        }
    }
    result = (unsigned char)pending_character();
done:
    restore_capacity_register();
    return result;
}
