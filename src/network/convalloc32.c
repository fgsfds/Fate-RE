// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "../engine/BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
/* Watcom 386 REGS ABI: six unsigned 32-bit registers and carry flag. */
union REGS { struct { unsigned int eax, ebx, ecx, edx, esi, edi, cflag; } x; };
int int386(int interrupt_number, union REGS *input, union REGS *output);

convalloc32 (long size)
{
	union REGS r;

	r.x.eax = 0x0100;           //DPMI allocate DOS memory
	r.x.ebx = ((size+15)>>4);   //Number of paragraphs requested
	int386(0x31,&r,&r);

	if (r.x.cflag != 0) return ((long)0);   //Failed
	return ((long)((r.x.eax&0xffff)<<4));   //Returns full 32-bit offset
}
