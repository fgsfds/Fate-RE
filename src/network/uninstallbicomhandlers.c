// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "../engine/BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
/* Minimal Watcom 386 interrupt-register ABI; byte BL is at offset four. */
union REGS {
    struct { unsigned int eax, ebx, ecx, edx, esi, edi, cflag; } x;
    struct { unsigned char al, ah; unsigned short pad1;
             unsigned char bl, bh; unsigned short pad2; } h;
};
struct SREGS { unsigned short es, cs, ss, ds, fs, gs; };
int int386(int number, union REGS *input, union REGS *output);
int int386x(int number, union REGS *input, union REGS *output, struct SREGS *segments);
extern long comvect;
extern unsigned short orig_pm_sel, orig_rm_seg, orig_rm_off;
extern unsigned long orig_pm_off;

uninstallbicomhandlers()
{
	union REGS r;
	struct SREGS sr;

		//restore old protected mode handler
	r.x.eax = 0x2500+comvect;   /* DOS set vector (INT 0Ch) */
	r.x.edx = orig_pm_off;
	sr.ds = orig_pm_sel;    /* DS:EDX == &handler */
	sr.es = 0;
	int386x(0x21,&r,&r,&sr);

		//restore old real mode handler
	r.x.eax = 0x0201;   /* DPMI set real mode vector */
	r.h.bl = comvect;
	r.x.ecx = (unsigned long)orig_rm_seg;     //CX:DX == real mode &handler
	r.x.edx = (unsigned long)orig_rm_off;
	int386(0x31,&r,&r);
}
