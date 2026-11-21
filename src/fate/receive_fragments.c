// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// See ../engine/BUILDLIC.TXT. Packet receiver operations from historical GAME.C.
/* Only unchanged compiler prefixes enter the receiver: low-button preparation
 * (17), checksum increment/add (3), message length scaling (10), and clock
 * addition/store (20). Normal C continuations and private RETs remain unlinked
 * and guarded. No CALL, RET, or stack operation is inserted between prefixes.
 * The real receiver supplies each following store, branch, or continuation.
 * receiver_button_bytes, receiver_crc_words, and receiver_crc_cursor are
 * separately named views of existing DS storage. Packed input words use the
 * Watcom/x86 unaligned representation. Packet indices and ring cursors are
 * bounded; clock and checksum calculations use unsigned 32-bit wrapping.
 */
extern unsigned char receiver_button_bytes[80], packet[546];
extern unsigned short cx_word(unsigned short), si_word(unsigned short);
#pragma aux cx_word = parm nomemory [cx] value [cx] modify exact nomemory [];
#pragma aux si_word = parm nomemory [si] value [si] modify exact nomemory [];
unsigned long receive_button_low(unsigned long, unsigned long);
#pragma aux receive_button_low parm [ebx] [eax] value [eax] modify exact [eax ecx esi];
unsigned long receive_button_low(unsigned long offset, unsigned long index)
{
    unsigned short old = cx_word(*(unsigned short *)(receiver_button_bytes + offset + 3));
    unsigned short byte = si_word(packet[index]);
    old &= 0xff00;
    *(unsigned short *)(receiver_button_bytes + offset + 3) = old | byte;
    return index + 1;
}

extern unsigned short receiver_crc_words[256];
extern unsigned long receiver_crc_cursor;
extern unsigned long edx_value(unsigned long), edi_value(unsigned long);
#pragma aux edx_value = parm nomemory [edx] value [edx] modify exact nomemory [];
#pragma aux edi_value = parm nomemory [edi] value [edi] modify exact nomemory [];
void receive_checksum_order(unsigned long, unsigned long, unsigned long);
#pragma aux receive_checksum_order parm [edx] [ebx] [edi] modify exact [edx edi];
void receive_checksum_order(unsigned long cursor, unsigned long high, unsigned long low)
{
    unsigned long next = edx_value(cursor + 1);
    unsigned long sum = edi_value(low + high);
    receiver_crc_words[next - 1] = (unsigned short)sum;
    receiver_crc_cursor = next & 255;
}

extern unsigned char message_length;
unsigned long receive_message_delta(void);
#pragma aux receive_message_delta parm [] value [eax] modify exact [eax];
unsigned long receive_message_delta(void)
{
    return (unsigned long)message_length << 4;
}

extern unsigned long totalclock, message_deadline;
void receive_message_clock(unsigned long);
#pragma aux receive_message_clock parm [eax] modify exact [edx];
void receive_message_clock(unsigned long delta)
{
    message_deadline = totalclock + 360UL + delta;
}
