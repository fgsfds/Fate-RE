/* Clear the remaining palette slots at the video-mode initialization handoff.
 * Empty ABI identities keep the caller's EBX live without emitting instructions.
 * The checked 19-byte loop falls through into the display reset. The private
 * compiler RET is excluded from the production slice. */
extern char *palookup[];
extern long current_bx(void);
#pragma aux current_bx = value [ebx] modify exact [];
extern void keep_bx(long);
#pragma aux keep_bx = "" parm [ebx] modify exact [];
#pragma aux palette_lookup parm [eax] modify exact [eax ecx];
void palette_lookup(long i)
{
    long saved = current_bx();
    for (; i < 256; ++i) palookup[i] = 0;
    keep_bx(saved);
}
