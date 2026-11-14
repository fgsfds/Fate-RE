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

#define COMCODEBYTES 384
#define COMBUFSIZ 16384
#define COMCODEOFFS 14
#define FP_OFF(p) ((unsigned)(p))
unsigned short FP_SEG(const void __far *);
#pragma aux FP_SEG = parm caller [eax dx] value [dx];
void __interrupt __far comhandler(void);
extern volatile short *inbufplc, *inbufend, *outbufplc, *outbufend, *comport;
extern volatile unsigned char *comtype, *comerror, *comresend, *incnt, *inbuf, *outbuf;
extern char rmbuffer[COMCODEBYTES], conventional_memory_error[];
long convalloc32(long size);
int printf(const char *format, ...);
void exit(int status);
void *memcpy(void *destination, const void *source, unsigned int count);

installbicomhandlers()
{
	union REGS r;
	struct SREGS sr;
	long lowp;
	void far *fh;

		//Get old protected mode handler
	r.x.eax = 0x3500+comvect;   /* DOS get vector (INT 0Ch) */
	sr.ds = sr.es = 0;
	int386x(0x21,&r,&r,&sr);
	orig_pm_sel = (unsigned short)sr.es;
	orig_pm_off = r.x.ebx;

		//Get old real mode handler
	r.x.eax = 0x0200;   /* DPMI get real mode vector */
	r.h.bl = comvect;
	int386(0x31,&r,&r);
	orig_rm_seg = (unsigned short)r.x.ecx;
	orig_rm_off = (unsigned short)r.x.edx;

		//Allocate memory in low memory to store real mode handler
	if ((lowp = convalloc32(COMCODEBYTES+(COMBUFSIZ<<1))) == 0)
		{ printf(conventional_memory_error); exit; }

	inbufplc = (short *)(lowp+0);
	inbufend = (short *)(lowp+2);
	outbufplc = (short *)(lowp+4);
	outbufend = (short *)(lowp+6);
	comport = (short *)(lowp+8);
	comtype = (char *)(lowp+10);
	comerror = (char *)(lowp+11);
	comresend = (char *)(lowp+12);
	incnt = (char *)(lowp+13);
	inbuf = (char *)(lowp+COMCODEBYTES);
	outbuf = (char *)(lowp+COMCODEBYTES+COMBUFSIZ);

	memcpy((void *)lowp,(void *)rmbuffer,COMCODEBYTES);

		//Set new protected mode handler
	r.x.eax = 0x2500+comvect;   /* DOS set vector (INT 0Ch) */
	fh = (void far *)comhandler;
	r.x.edx = FP_OFF(fh);
	sr.ds = FP_SEG(fh);      //DS:EDX == &handler
	sr.es = 0;
	int386x(0x21,&r,&r,&sr);

		//Set new real mode handler (must be after setting protected mode)
	r.x.eax = 0x0201;
	r.h.bl = comvect;              //CX:DX == real mode &handler
	r.x.ecx = ((lowp>>4)&0xffff);  //D32realseg
	r.x.edx = COMCODEOFFS;         //D32realoff
	int386(0x31,&r,&r);
}
