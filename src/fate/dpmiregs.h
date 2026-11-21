#ifndef FATE_DPMI_REGS_H
#define FATE_DPMI_REGS_H

/* Register blocks shared by the DOS DPMI service 0300h calls. */
#pragma pack(push, 1)
typedef struct {
    unsigned long edi, esi, ebp, reserved;
    unsigned long ebx, edx, ecx, eax;
    unsigned short flags, es, ds, fs, gs, ip, cs, sp, ss;
} RealModeRegisters;
typedef struct {
    unsigned short ax, bx, cx, dx, si, di, carry;
} BiosRegisters;
typedef union {
    unsigned long value;
    struct { unsigned short low, upper; } words;
    struct { unsigned char low, high, unused[2]; } bytes;
} DpmiRegister;
typedef struct {
    DpmiRegister eax, ebx, ecx, edx, esi, edi, carry;
} DpmiRegisters;
typedef struct {
    unsigned short es, cs, ss, ds, fs, gs;
} DpmiSegments;
#pragma pack(pop)

extern void *memset(void *, int, unsigned);
#pragma aux memset modify exact [eax ebx edx];
extern void segread(DpmiSegments *);
#pragma aux segread modify exact [eax];
extern int int386x(int, DpmiRegisters *, DpmiRegisters *, DpmiSegments *);
#pragma aux int386x modify exact [eax ebx ecx edx];
extern void restore_dos_segments(void);
#pragma aux restore_dos_segments = "cld" "mov ax, ds" "mov es, ax" modify exact [eax];

#endif
