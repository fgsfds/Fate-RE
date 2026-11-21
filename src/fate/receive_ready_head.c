/* Select the 18-byte head load, stage store, and comparison. The receiver
 * supplies the following branch and consumes ZF and CX. The standalone
 * by-value tail places sender at ESP+12, matching the existing receiver frame;
 * no call, stack copy, or stack adjustment is linked. Volatile views preserve
 * the recorded access widths and order, without claiming synchronization.
 */
// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// See ../engine/BUILDLIC.TXT. Adapted from the receiver's GAME.C readiness case.

typedef struct {
    short length, reserved_length;
    unsigned long snapshots;
    volatile short sender;
    short reserved_sender;
} ReceiveFrameTail;

typedef char ReceiveFrameTailLayout[sizeof(ReceiveFrameTail) == 12 ? 1 : -1];

extern short connecthead;
extern unsigned char peer_ready_stage[16];

extern short ready_head_in_cx(short);
#pragma aux ready_head_in_cx = parm nomemory [cx] value [cx] modify exact nomemory [];

extern void receive_ready_send(unsigned long);
#pragma aux receive_ready_send parm [ecx] modify exact [eax ebx edx];

void receive_ready_context(long, unsigned long, ReceiveFrameTail);
#pragma aux receive_ready_context parm caller [eax] [edx] [] modify exact [eax ebx ecx edx];

void receive_ready_context(long sender_index, unsigned long stage_register, ReceiveFrameTail frame)
{
    unsigned char stage = (unsigned char)stage_register;
    short head = ready_head_in_cx(*(volatile short *)&connecthead);

    ((volatile unsigned char *)peer_ready_stage)[sender_index] = stage;
    if (head == frame.sender && stage == 2)
        receive_ready_send((unsigned short)head);
}