/* ECX and the shared frame's +4 word are linear addresses in the same
 * RipplePlane, both below INT32_MAX in the original DATA object. Their
 * signed full-width comparison corresponds to the legacy near JL. */
extern void ripple_output_more_words(void);
#pragma aux ripple_output_more_words parm [] aborts modify exact [];

void ripple_output_word_guard(long, long);
#pragma aux ripple_output_word_guard parm caller [ecx] [] modify exact [];

void ripple_output_word_guard(long center_address, long end_address)
{
    if (center_address < end_address)
        ripple_output_more_words();
}

/* The selected fragment follows successful completion of a row and
 * receives EBP in 0..127. EBP is the actual result of this context. */
extern int ripple_output_row_ebp(void);
#pragma aux ripple_output_row_ebp = "" parm [] value [ebp] modify exact [];

int ripple_output_row_increment(void);
#pragma aux ripple_output_row_increment parm [] value [ebp] modify exact [];

int ripple_output_row_increment(void)
{
    return ripple_output_row_ebp() + 1;
}

/* The retained output setup initializes EBP to zero. Row completion
 * advances it once, keeping the full value in 0..128 at each guard. */
extern void ripple_output_more_rows(void);
#pragma aux ripple_output_more_rows parm [] aborts modify exact [];

extern int ripple_frame;

void ripple_output_row_guard(void);
#pragma aux ripple_output_row_guard parm [] modify exact [];

void ripple_output_row_guard(void)
{
    if (ripple_output_row_ebp() < 128)
        ripple_output_more_rows();

    ++*(unsigned int *)&ripple_frame;
}
