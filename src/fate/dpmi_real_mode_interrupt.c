#include "dpmiregs.h"

int dpmi_real_mode_interrupt(int interrupt_no, const BiosRegisters *input, BiosRegisters *output);
#pragma aux dpmi_real_mode_interrupt parm routine [eax] [edx] [ebx] modify exact [eax ebx edx];
int dpmi_real_mode_interrupt(int interrupt_no, const BiosRegisters *input, BiosRegisters *output)
{
    RealModeRegisters real;
    DpmiRegisters regs;
    DpmiSegments segments;

    memset(&real, 0, sizeof(real));
    real.eax = input->ax;
    real.ebx = input->bx;
    real.ecx = input->cx;
    real.edx = input->dx;
    real.esi = input->si;
    real.edi = input->di;

    /* DPMI service 0300h uses the low parts of EAX, EBX, and ECX. */
    segread(&segments);
    regs.eax.words.low = 0x300;
    regs.ebx.bytes.low = interrupt_no;
    regs.ebx.bytes.high = 0;
    regs.ecx.words.low = 0;
    segments.es = segments.ds;
    regs.edi.value = (unsigned long)&real;
    int386x(0x31, &regs, &regs, &segments);
    restore_dos_segments();

    output->ax = real.eax;
    output->bx = real.ebx;
    output->cx = real.ecx;
    output->dx = real.edx;
    output->si = real.esi;
    output->di = real.edi;
    output->carry = real.flags & 1;
    return output->ax;
}
