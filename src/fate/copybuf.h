/* "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman.
 * Ken Silverman's official web site: http://www.advsys.net/ken
 * See ../engine/BUILDLIC.TXT for license information.
 * copybuf pragma from pinned Build PRAGMAS.H, commit
 * 88ffca1bdb8d93c731f6d02e62ae5119393bc73b. Copies count doublewords.
 * Adaptation: EAX is conservatively declared scratch to reproduce the caller's
 * allocation. This is an inferred compiler contract, not the original spelling;
 * REP MOVSD itself does not change EAX. Callers must ignore any return value.
 */
extern void copybuf(const void *source, void *destination, unsigned count);
#pragma aux copybuf = "rep movsd" parm [esi][edi][ecx] modify exact [eax ecx esi edi]
