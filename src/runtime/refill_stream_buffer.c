#include "rtstream.h"

extern unsigned char *allocate_stream_buffer(RuntimeStream *);
#pragma aux allocate_stream_buffer modify exact [eax];
extern int flush_matching_streams(unsigned long);
#pragma aux flush_matching_streams modify exact [eax];
extern int read_console_character(void);
#pragma aux read_console_character modify exact [eax];
extern long read_descriptor_raw(int, void *, unsigned);
#pragma aux read_descriptor_raw modify exact [eax ebx edx];

/* Preserve the original register-call stream pointer across DOS reads. */
extern void save_stream(RuntimeStream *);
#pragma aux save_stream = parm [ecx] modify exact [];
extern RuntimeStream *buffered_stream(void);
#pragma aux buffered_stream = value [ecx] modify exact [];
extern RuntimeStream *incoming_stream(void);
#pragma aux incoming_stream = value [eax] modify exact [];
extern unsigned char flag_in_ah(unsigned char);
#pragma aux flag_in_ah = parm [ah] value [ah] modify exact [];
extern unsigned char flag_in_bl(unsigned char);
#pragma aux flag_in_bl = parm [bl] value [bl] modify exact [];
extern unsigned char flag_in_al(unsigned char);
#pragma aux flag_in_al = parm [al] value [al] modify exact [];
extern unsigned long flag_word_in_edx(unsigned long);
#pragma aux flag_word_in_edx = parm [edx] value [edx] modify exact [];
extern unsigned char *buffer_in_eax(unsigned char *);
#pragma aux buffer_in_eax = parm [eax] value [eax] modify exact [];
extern unsigned char *buffer_in_ebx(unsigned char *);
#pragma aux buffer_in_ebx = parm [ebx] value [ebx] modify exact [];
extern long in_ebx(long);
#pragma aux in_ebx = parm [ebx] value [ebx] modify exact [];
extern long count_in_esi(long);
#pragma aux count_in_esi = parm [esi] value [esi] modify exact [];
extern unsigned char character_in_al(void);
#pragma aux character_in_al = value [al] modify exact [];

long fill_buffer(RuntimeStream *);
#pragma aux fill_buffer modify exact [eax];
long fill_buffer(RuntimeStream *stream)
{
    unsigned char mode, flags;
    unsigned long word;
    unsigned char *buffer;
    long count, descriptor;

    save_stream(stream);
    if (!incoming_stream()->buffer)
        allocate_stream_buffer(incoming_stream());

    mode = flag_in_ah(buffered_stream()->flags.bytes[1]);
    if ((mode & 0x20) && (mode & 6))
        flush_matching_streams(0x2000UL);

    /* Reset the input cursor and clear the stream pushback flag. */
    word = flag_word_in_edx(buffered_stream()->flags.word);
    flags = flag_in_bl(buffered_stream()->flags.bytes[0]);
    buffer = buffer_in_eax(buffered_stream()->buffer);
    flags = flag_in_bl(flags & ~4);
    *(unsigned char *volatile *)&buffered_stream()->next = buffer;
    word = flag_word_in_edx(word & 0x2400);
    buffered_stream()->flags.bytes[0] = flags;
    if (word == 0x2400) {
        descriptor = in_ebx(buffered_stream()->descriptor);
        if (!descriptor) {
            buffered_stream()->buffered = descriptor;
            if (read_console_character() != -1) {
                buffer = buffer_in_ebx(buffered_stream()->next);
                *buffer = character_in_al();
                buffered_stream()->buffered = 1;
            }
            goto check_count;
        }
    }

    if (buffered_stream()->flags.bytes[1] & 4)
        count = in_ebx(1);
    else
        count = in_ebx(buffered_stream()->capacity);
    buffered_stream()->buffered = read_descriptor_raw(buffered_stream()->descriptor,
                                                     buffered_stream()->next, count);

check_count:
    count = count_in_esi(buffered_stream()->buffered);
    if (count > 0)
        goto done;
    if (!count) {
        *(volatile unsigned char *)&buffered_stream()->flags.bytes[0] |= 0x10;
        goto done;
    }
    flags = flag_in_al(buffered_stream()->flags.bytes[0]);
    *(volatile long *)&buffered_stream()->buffered = 0;
    flags = flag_in_al(flags | 0x20);
    buffered_stream()->flags.bytes[0] = flags;
done:
    return buffered_stream()->buffered;
}
