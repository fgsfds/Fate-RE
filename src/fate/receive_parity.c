// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// See ../engine/BUILDLIC.TXT. Adapted from the receiver's GAME.C parity logic.
/* Production selects only the seven-byte mask/narrow/TEST prefix. Incoming
 * EAX is the unsigned snapshot count; outgoing ZF is consumed by the existing
 * receiver branch. The rest of this real C parity/tick function is unlinked.
 * No stack frame or instruction-bearing assembly auxiliary is used. */
extern unsigned long last_tick;
extern int random_value(void);
#pragma aux random_value parm [] value [eax] modify exact [eax];
extern short masked_word(short);
#pragma aux masked_word = parm nomemory [ax] value [ax] modify exact nomemory [];
extern long full_value(long);
#pragma aux full_value = parm nomemory [eax] value [eax] modify exact nomemory [];
void receiver_parity_tick(unsigned long);
#pragma aux receiver_parity_tick parm [eax] modify exact [eax];
void receiver_parity_tick(unsigned long count)
{
    if (full_value(masked_word((short)(count & 1UL))) == 0) {
        if (random_value() & 1) ++last_tick;
        else --last_tick;
    }
}
