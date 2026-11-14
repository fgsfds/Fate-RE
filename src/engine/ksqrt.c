// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
extern unsigned short sqrtable[];

#pragma aux ksqrtasm = \
	"test eax, eax",\
	"jns skipnegate",\
	"neg eax",\
	"skipnegate: bsr ecx, eax",\
	"cmp cl, 11",\
	"jge short over2048",\
	"movzx eax, word ptr sqrtable[eax*2]",\
	"jmp short end",\
	"over2048: sub cl, 9",\
	"and cl, 0xfe",\
	"sar eax, cl",\
	"movzx eax, word ptr sqrtable[eax*2]",\
	"sar cl, 1",\
	"shl eax, cl",\
	"end: sar eax, 10",\
	parm nomemory [eax]\
	modify exact [eax ebx ecx edx]\

ksqrt(long num)
{
    return(ksqrtasm(num));
}
