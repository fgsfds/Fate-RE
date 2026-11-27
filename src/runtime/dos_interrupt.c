#include "dpmiregs.h"

/* The assembly dispatcher uses EDX for output and EDI for input. */
extern void dispatch_interrupt_registers(DpmiRegisters *, DpmiRegisters *, int, DpmiSegments *);
#pragma aux dispatch_interrupt_registers parm [edx] [edi] [esi] [ebx] modify exact [eax ebx ecx edx esi edi];

int int386x(int vector, DpmiRegisters *input, DpmiRegisters *output, DpmiSegments *segments)
{
    dispatch_interrupt_registers(output, input, vector, segments);
    return output->eax.value;
}

int int386(int, DpmiRegisters *, DpmiRegisters *);
#pragma aux int386 modify exact [eax ebx edx];
extern void vector_in_ecx(int);
#pragma aux vector_in_ecx = parm [ecx] modify exact [];
extern int saved_vector(void);
#pragma aux saved_vector = value [ecx] modify exact [];
int int386(int vector, DpmiRegisters *input, DpmiRegisters *output)
{
    DpmiSegments segments;
    vector_in_ecx(vector);
    segread(&segments);
    return int386x(saved_vector(), input, output, &segments);
}
