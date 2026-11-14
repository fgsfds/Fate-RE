// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "../engine/BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
union REGS {
    struct { unsigned int eax, ebx, ecx, edx, esi, edi, cflag; } x;
    struct { unsigned short ax, pad1, bx, pad2, cx, pad3; } w;
    struct { unsigned char al, ah; unsigned short pad1;
             unsigned char bl, bh; unsigned short pad2; } h;
};
struct SREGS { unsigned short es, cs, ss, ds, fs, gs; };
int int386x(int number, union REGS *input, union REGS *output, struct SREGS *segments);
void *memset(void *destination, int value, unsigned int count);
#define FP_OFF(p) ((unsigned)(p))
unsigned short FP_SEG(const void __far *);
#pragma aux FP_SEG = parm caller [eax dx] value [dx];
#pragma aux fixregistersaftersimulate = "cld", "mov ax, ds", "mov es, ax"
#pragma pack(push,1)
struct rminfo {
    long EDI, ESI, EBP, ESP, EBX, EDX, ECX, EAX;
    short flags, ES, DS, FS, GS, IP, CS, SP, SS;
};
#pragma pack(pop)
extern struct rminfo RMI;
extern long rmoffset32, rmsegment16;

simulateint(char intnum, long daeax, long daebx, long daecx, long daedx, long daesi, long daedi)
{
	union REGS regs;
	struct SREGS sregs;

	memset(&RMI,0,sizeof(RMI));    // Set up real-mode call structure
	memset(&sregs,0,sizeof(sregs));

	RMI.EAX = daeax;
	RMI.EBX = daebx;
	RMI.ECX = daecx;
	RMI.EDX = daedx;
	RMI.ESI = daesi-rmoffset32;
	RMI.EDI = daedi-rmoffset32;
	RMI.DS = rmsegment16;
	RMI.ES = rmsegment16;

	regs.w.ax = 0x0300;            // Use DMPI call 300h to issue the DOS interrupt
	regs.h.bl = intnum;
	regs.h.bh = 0;
	regs.w.cx = 0;
	sregs.es = FP_SEG(&RMI);
	regs.x.edi = FP_OFF(&RMI);
	int386x(0x31,&regs,&regs,&sregs);

	fixregistersaftersimulate();

	return(RMI.EAX);
}
