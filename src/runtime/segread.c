#include "dpmiregs.h"

extern DpmiSegments *output_in_edx(DpmiSegments *);
#pragma aux output_in_edx = parm [edx] value [edx] modify exact [];

/* Encode MOV from a selector to EAX directly for the Watcom assembler. */
extern unsigned short read_cs(void);
#pragma aux read_cs = 0x8c 0xc8 value [ax] modify exact [eax];
extern unsigned short read_ds(void);
#pragma aux read_ds = 0x8c 0xd8 value [ax] modify exact [eax];
extern unsigned short read_es(void);
#pragma aux read_es = 0x8c 0xc0 value [ax] modify exact [eax];
extern unsigned short read_ss(void);
#pragma aux read_ss = 0x8c 0xd0 value [ax] modify exact [eax];
extern unsigned short read_fs(void);
#pragma aux read_fs = 0x8c 0xe0 value [ax] modify exact [eax];
extern unsigned short read_gs(void);
#pragma aux read_gs = 0x8c 0xe8 value [ax] modify exact [eax];

void segread(DpmiSegments *out)
{
    DpmiSegments *segments = output_in_edx(out);

    segments->cs = read_cs();
    segments->ds = read_ds();
    segments->es = read_es();
    segments->ss = read_ss();
    segments->fs = read_fs();
    segments->gs = read_gs();
}
