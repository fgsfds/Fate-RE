/* Select only the 13-byte register argument setup. Watcom tail-jumps to
 * sendpacket in the standalone wrapper; the receiver supplies its own CALL.
 * Only incoming CX is meaningful; discard the upper half before promotion.
 */
// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// See ../engine/BUILDLIC.TXT. Adapted from the receiver's GAME.C readiness case.

extern unsigned char packet[546];

extern int ready_length_in_ebx(int);
#pragma aux ready_length_in_ebx = parm nomemory [ebx] value [ebx] modify exact nomemory [];
extern unsigned char *ready_packet_in_edx(unsigned char *);
#pragma aux ready_packet_in_edx = parm nomemory [edx] value [edx] modify exact nomemory [];

extern void sendpacket(int, unsigned char *, int);
#pragma aux sendpacket parm [eax] [edx] [ebx] modify exact [eax ebx edx];

void receive_ready_send(unsigned long);
#pragma aux receive_ready_send parm [ecx] modify exact [eax ebx edx];

/* Only the low 16 bits of incoming ECX carry the peer index. */
void receive_ready_send(unsigned long head_register)
{
    int length = ready_length_in_ebx(2);
    unsigned char *data = ready_packet_in_edx(packet);

    sendpacket((short)(unsigned short)head_register, data, length);
}