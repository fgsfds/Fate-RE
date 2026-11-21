#pragma pack(push, 1)
typedef struct {
    unsigned long edi, esi, ebp, reserved;
    unsigned long ebx, edx, ecx, eax;
    unsigned short flags, es, ds, fs, gs, ip, cs, sp, ss;
} RealModeRegisters;
#pragma pack(pop)
extern void *memset(void *, int, unsigned);
#pragma aux memset modify exact [eax edx ebx];
extern unsigned short FP_SEG(const void __far *);
#pragma aux FP_SEG = parm caller [eax dx] value [dx];

typedef struct {
    unsigned long eax, ebx, ecx, edx, esi, edi, carry;
} DpmiRegisters;
typedef struct {
    unsigned short es, cs, ss, ds, fs, gs;
} DpmiSegments;
extern void segread(DpmiSegments *);
#pragma aux segread modify exact [eax];
extern int int386x(int, DpmiRegisters *, DpmiRegisters *, DpmiSegments *);
#pragma aux int386x modify exact [eax ebx ecx edx];

int simulate_real_mode_interrupt(int interrupt_no, RealModeRegisters *real_regs)
{
    DpmiRegisters regs;
    DpmiSegments segs;
    memset(&regs, 0, sizeof(regs));
    segread(&segs);
    regs.eax = 0x300;
    regs.ebx = (short)interrupt_no;
    regs.ecx = 0;
    segs.es = FP_SEG((void __far *)real_regs);
    regs.edi = (unsigned long)real_regs;
    real_regs->sp = 0;
    real_regs->flags = 0;
    real_regs->ss = real_regs->sp;
    return int386x(0x31, &regs, &regs, &segs);
}
