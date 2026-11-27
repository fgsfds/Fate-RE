// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
extern char moustat;
#pragma aux readmousexy =\
	"mov ax, 11d",\
	"int 33h",\
	"mov [esi], cx",\
	"mov [edi], dx",\
	parm [esi][edi]\
	modify exact [eax ebx ecx edx]\

#pragma aux readmousebstatus =\
	"mov ax, 5d",\
	"int 33h",\
	"mov [esi], ax",\
	parm [esi]\
	modify exact [eax ebx ecx edx]\

getmousevalues(short *mousx, short *mousy, short *bstatus)
{
	if (moustat == 0) { *mousx = 0; *mousy = 0; *bstatus = 0; return; }
	readmousexy(mousx,mousy);
	readmousebstatus(bstatus);
}

extern unsigned long mouse_bios_reset(void);
#pragma aux mouse_bios_reset = "mov ax, 0" "int 33h" value [eax] modify exact [eax];

int initialize_mouse(void)
{
    unsigned result = mouse_bios_reset() & 0xffffu;
    moustat = (unsigned char)result;
    return (unsigned char)result;
}
