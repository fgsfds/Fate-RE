extern unsigned long legacy_rgb_palette[];
/* The search leaves the original color in EAX and the index in EBX. */
extern unsigned hold_color_in_eax(void);
extern void retain_input_color(unsigned);
#pragma aux retain_input_color = parm [eax] modify exact [];
#pragma aux hold_color_in_eax = value [eax] modify exact [];
extern void set_index_in_ebx(int);
extern int get_index_from_ebx(void);
#pragma aux get_index_from_ebx = value [ebx] modify exact [];
#pragma aux set_index_in_ebx = parm [ebx] modify exact [];
extern int hold_table_index(int);
#pragma aux hold_table_index = parm [edx] value [edx] modify exact [];
long find_legacy_palette_index(long color);
#pragma aux find_legacy_palette_index modify exact [eax];
long find_legacy_palette_index(long color)
{
    union { unsigned value; unsigned char byte[4]; } result;
    set_index_in_ebx(0);
    retain_input_color(color);
    goto check;
    do {
        int index = get_index_from_ebx();
        if (hold_color_in_eax() == legacy_rgb_palette[hold_table_index((short)index)])
            return index;
        set_index_in_ebx(index + 1);
check:
        ;
    } while ((short)get_index_from_ebx() < 16);
    result.value = hold_color_in_eax();
    result.byte[0] &= 15;
    result.byte[1] = 0;
    return result.value;
}
