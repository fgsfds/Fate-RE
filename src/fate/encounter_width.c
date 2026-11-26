/* Sign-extend the actual width word while preserving EAX and other inputs.
 * The pinned compiler interprets the short conversion as low-word truncation.
 * Only the signed promotion is placed; the private RET remains guarded.
 */
extern int encounter_width_context(int value);
#pragma aux encounter_width_context parm [eax] value [ebx] modify exact [ebx];

int encounter_width_context(int value)
{
    return (short)value;
}
