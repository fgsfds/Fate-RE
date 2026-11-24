typedef struct {
    unsigned long eax, ebx, ecx, edx, esi, edi, carry;
} DpmiRegisters;
extern int int386(int, DpmiRegisters *, DpmiRegisters *);
#pragma aux int386 modify exact [eax ebx edx];

extern unsigned short dos_segment, dos_buffer_offset;

void __far *allocate_dos_memory(short size)
{
    DpmiRegisters regs;
    regs.eax = 0x100;
    regs.ebx = (size + 16) / 16;
    int386(0x31, &regs, &regs);
    if (!regs.carry) {
        dos_segment = (unsigned short)regs.eax;
        dos_buffer_offset = 0;
        return (void __far *)(void *)((unsigned long)(unsigned short)regs.eax << 4);
    }
    return 0;
}

extern unsigned video_dos_allocation;
extern void restore_dos_segments(void);
#pragma aux restore_dos_segments = "cld" "mov ax, ds" "mov es, ax" modify exact [eax];

void free_video_dos_memory(void)
{
    union {
        DpmiRegisters registers;
        unsigned short word[14];
    } packet;
    packet.word[0] = 0x101;
    packet.word[6] = (unsigned short)video_dos_allocation;
    int386(0x31, &packet.registers, &packet.registers);
    restore_dos_segments();
}
