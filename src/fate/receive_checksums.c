// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// See ../engine/BUILDLIC.TXT. Fate's word-checksum receive comparison.
/* Production selects the 105-byte body before its verified private RET.
 * Its RET address is the original snapshot continuation (0x325e2); the body
 * has no stack/frame instructions. These volatile cursor names are explicit
 * views of existing DS storage, not new objects or conflicting declarations.
 * The original shared ring-control fields are read at each recorded phase.
 * Cursors are 0..255; the outer receiver saves all six scratch registers.
 * The normal compiler RET is unlinked; completion is the next snapshot block.
 */
extern volatile long checksum_write_cursor, checksum_received_cursor, checksum_read_cursor;
extern short generated_checksum[256], received_checksum[256], sync_error;
extern long eax_value(long), ecx_value(long), edi_value(long);
#pragma aux eax_value = parm nomemory [eax] value [eax] modify exact nomemory [];
#pragma aux ecx_value = parm nomemory [ecx] value [ecx] modify exact nomemory [];
#pragma aux edi_value = parm nomemory [edi] value [edi] modify exact nomemory [];
extern short cx_word(short), dx_word(short), bx_word(short), si_word(short);
#pragma aux cx_word = parm nomemory [cx] value [cx] modify exact nomemory [];
#pragma aux dx_word = parm nomemory [dx] value [dx] modify exact nomemory [];
#pragma aux bx_word = parm nomemory [bx] value [bx] modify exact nomemory [];
#pragma aux si_word = parm nomemory [si] value [si] modify exact nomemory [];
void compare_received_checksums(void);
#pragma aux compare_received_checksums parm [] modify exact [eax ebx ecx edx esi edi];
void compare_received_checksums(void)
{
    long available = eax_value(checksum_write_cursor);
    long consumed = ecx_value(checksum_read_cursor);
    long current;
    if (available != consumed && consumed != checksum_received_cursor) {
        sync_error = si_word(0);
        do {
            long next = eax_value(checksum_read_cursor + 1);
            short error = cx_word(sync_error);
            short generated = dx_word(generated_checksum[next - 1]);
            short received = bx_word(received_checksum[next - 1]);
            short mismatch;
            next = eax_value(next & 255);
            mismatch = dx_word((short)(generated ^ received));
            checksum_read_cursor = next;
            error = cx_word((short)(error | mismatch));
            available = eax_value(checksum_write_cursor);
            current = edi_value(checksum_read_cursor);
            sync_error = error;
        } while (available != current && current != checksum_received_cursor);
    }
}
