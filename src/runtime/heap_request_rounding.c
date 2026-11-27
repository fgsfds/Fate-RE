extern const volatile unsigned char dos_extender_type, extender_subtype;
extern volatile unsigned long minimum_heap_growth;
extern unsigned long available_at_break(void);
#pragma aux available_at_break "free_space_at_break_" modify exact [eax];
extern void save_request(unsigned long *);
#pragma aux save_request = parm [ebx] modify exact [];
extern unsigned long *incoming_request(void);
#pragma aux incoming_request = value [eax] modify exact [];
extern unsigned long *current_request(void);
#pragma aux current_request = value [ebx] modify exact [];
extern unsigned long in_edx(unsigned long);
#pragma aux in_edx = parm [edx] value [edx] modify exact [];
extern unsigned long in_esi(unsigned long);
#pragma aux in_esi = parm [esi] value [esi] modify exact [];
/* The masks operate on the corresponding bytes of the 32-bit size. */
extern unsigned long round_dword_down(unsigned long);
#pragma aux round_dword_down = "and dl,0fch" parm [edx] value [edx] modify exact [];
extern unsigned long round_word_down(unsigned long);
#pragma aux round_word_down = "and dl,0feh" parm [edx] value [edx] modify exact [];
extern unsigned long round_page_down(unsigned long);
#pragma aux round_page_down = "and dh,0f0h" "xor dl,dl" parm [edx] value [edx] modify exact [];
extern unsigned result_from_al(unsigned char);
#pragma aux result_from_al = parm [al] value [eax] modify exact [];

int round_heap_request(unsigned long *size);
#pragma aux round_heap_request modify exact [eax];
int round_heap_request(unsigned long *size)
{
    unsigned long rounded, minimum;
    save_request(size);

    rounded = round_dword_down(in_edx(*incoming_request() + 3));
    if (rounded)
        goto check_extender;
failed:
    return 0;

check_extender:
    if ((dos_extender_type == 1 && extender_subtype == 0) || dos_extender_type == 9)
        rounded = in_edx(rounded + 8);
    else
        rounded = in_edx(rounded - available_at_break());

    *current_request() = rounded;
    rounded += 60;
    if (rounded < *(volatile unsigned long *)current_request())
        goto failed;
    minimum = in_esi(minimum_heap_growth);
    if (rounded < minimum)
        rounded = round_word_down(minimum);

    *current_request() = rounded;
    rounded = in_edx(rounded + 4095);
    if (rounded < *(volatile unsigned long *)current_request())
        goto failed;
    rounded = round_page_down(rounded);
    *current_request() = rounded;
    return result_from_al(rounded != 0) & 0xff;

}

/* The optional near-heap expansion hook reports failure. */
int request_more_heap(void)
{
    return 0;
}
